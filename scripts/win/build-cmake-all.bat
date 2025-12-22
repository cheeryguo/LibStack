@echo off
:: ===========================================
:: Build third-party libraries for Windows
:: Supports: MSVC/MinGW, x86/x64, Release/Debug
:: Installs to shared folders per architecture
:: ===========================================

:: Configuration
set SRC_DIR=../../src
set BUILD_DIR=../../build
set INSTALL_DIR=../../install

:: Architectures and configurations
set ARCHITECTURES=x86
set CONFIGURATIONS=Release Debug

:: Compiler settings (true for MSVC, false for MinGW)
set USE_MSVC=true
:: MSVC generator (adjust for your VS version)
set GENERATOR="Visual Studio 17 2022"
:: MinGW generator
set MINGW_GENERATOR="MinGW Makefiles"

:: Clean old builds (uncomment if needed)
:: rmdir /s /q %BUILD_DIR%
:: rmdir /s /q %INSTALL_DIR%

:: Main loop
for %%a in (%ARCHITECTURES%) do (
    for %%c in (%CONFIGURATIONS%) do (
        call :build_project %%a %%c
    )
)

echo All builds completed!
goto :eof

:: ===========================================
:: Build function
:: ===========================================
:build_project
setlocal
set arch=%1
set config=%2

echo Building %arch% (%config%)...

:: Set build path (unique per config)
set build_path=%BUILD_DIR%\%arch%-%config%
:: Set install path (shared per arch)
set install_path=%INSTALL_DIR%\%arch%-win

mkdir "%build_path%" 2>nul
mkdir "%install_path%" 2>nul

pushd "%build_path%"

:: Architecture-specific flags
set cmake_flags=-DCMAKE_INSTALL_PREFIX=../../%install_path% -DCMAKE_BUILD_TYPE=%config% -DOPENSSL_ROOT_DIR=../../%install_path%

if "%USE_MSVC%"=="true" (
    if "%arch%"=="x86" (
        set cmake_flags=%cmake_flags% -A Win32
    ) else if "%arch%"=="x64" (
        set cmake_flags=%cmake_flags% -A x64
    )
    set generator=%GENERATOR%
) else (
    if "%arch%"=="x86" (
        set cmake_flags=%cmake_flags% -DCMAKE_C_FLAGS=-m32 -DCMAKE_CXX_FLAGS=-m32
    )
    set generator=%MINGW_GENERATOR%
)

:: Run CMake
cmake -G %generator% %cmake_flags% ../..

:: Build and install
if "%USE_MSVC%"=="true" (
    cmake --build . --config %config%
    cmake --install . --config %config%
) else (
    mingw32-make -j4
    mingw32-make install
)

popd
endlocal
goto :eof