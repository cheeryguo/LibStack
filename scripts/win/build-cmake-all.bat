@echo off
:: ===========================================
:: Build script for Windows (Multi-Arch & Multi-Config)
:: Usage: build.bat [arch] [config]
:: Supports: x86/x64, Release/Debug
:: Installs to shared folders per architecture
:: Examples: 
::   build.bat all all      (Builds everything)
::   build.bat x64 Release  (Builds specific)

:: ===========================================

:: Set arguments with defaults
:: Use %1 from GitHub Actions matrix (e.g., x64 or x86)
set USER_ARCH=%~1
if "%USER_ARCH%"=="" set USER_ARCH=x64

:: Use %2 from GitHub Actions (e.g., Release)
set USER_CONFIG=%~2
if "%USER_CONFIG%"=="" set USER_CONFIG=Release

:: Configuration
set SRC_DIR=../../src
set BUILD_ROOT=build
set INSTALL_ROOT=install

set GENERATOR="Visual Studio 17 2022"

echo ===========================================
echo Requested Arch   : %USER_ARCH%
echo Requested Config : %USER_CONFIG%
echo ===========================================

:: Clean old builds (uncomment if needed)
:: rmdir /s /q %BUILD_DIR%
:: rmdir /s /q %INSTALL_DIR%

:: 1. Handle Architecture Loop
if /I "%USER_ARCH%"=="all" (
    call :handle_config x86 %USER_CONFIG%
    call :handle_config x64 %USER_CONFIG%
) else (
    call :handle_config %USER_ARCH% %USER_CONFIG%
)

echo.
echo All requested tasks completed!
goto :eof

:: ===========================================
:: Function: Handle Configuration Loop
:: ===========================================
:handle_config
set current_arch=%1
set current_config=%2

if /I "%current_config%"=="all" (
    call :build_project %current_arch% Release
    call :build_project %current_arch% Debug
) else (
    call :build_project %current_arch% %current_config%
)
goto :eof

:: ===========================================
:: Build function
:: ===========================================
:build_project
setlocal
set arch=%1
set config=%2

:: Capture the absolute path of the project root (where this script is located)
:: If the script is in 'scripts/win/', use %~dp0..\..
:: If the script is in the root, use %~dp0
set "PROJ_ROOT=%~dp0"

:: Use ^| to escape the pipe character in Batch
echo.
echo --------------------------------------------------------
echo Starting build for Architecture: %arch% ^| Configuration: %config%
echo --------------------------------------------------------

:: Set build path (unique per config)
set build_path=%BUILD_ROOT%\%arch%-%config%
:: Set install path (shared per arch)
set install_path=%INSTALL_ROOT%\%arch%-win

if not exist "%build_path%" mkdir "%build_path%"
if not exist "%install_path%" mkdir "%install_path%"

pushd "%build_path%"

:: 1. Define CMake flags
:: Use absolute paths for INSTALL_PREFIX to avoid confusion
set "abs_install_path=%PROJ_ROOT%%install_path%"
set cmake_flags=-DCMAKE_INSTALL_PREFIX="%abs_install_path%" -DCMAKE_BUILD_TYPE=%config%

:: 2. Set MSVC architecture flag
if /I "%arch%"=="x86" (
    set cmake_flags=%cmake_flags% -A Win32
) else (
    set cmake_flags=%cmake_flags% -A x64
)

:: 3. Run CMake configuration
:: Use "%PROJ_ROOT%" instead of "../../" to precisely locate CMakeLists.txt
cmake -G %GENERATOR% %cmake_flags% "%PROJ_ROOT%"

if %ERRORLEVEL% neq 0 (
    echo [ERROR] CMake Configuration failed for %arch%-%config%
    exit /b %ERRORLEVEL%
)

:: 4. Build and Install
:: --target install will trigger both build and installation
cmake --build . --config %config% --target install

if %ERRORLEVEL% neq 0 (
    echo [ERROR] Build failed for %arch%-%config%
    exit /b %ERRORLEVEL%
)

popd
endlocal
goto :eof