@echo off
setlocal enabledelayedexpansion

:: =============================================
:: CONFIGURATION (Modify these paths as needed)
:: =============================================
set ROOT_DIR=%~dp0
set OPENSSL_SOURCE=%ROOT_DIR%src\openssl-3.5.0
set PERL=C:\Strawberry\perl\bin\perl.exe
set NASM=C:\Strawberry\c\bin\nasm.exe
set VS_VCVARS="C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"

:: =============================================
:: BUILD PROCESS
:: =============================================

echo [INFO] Building OpenSSL for x86 and x64...

:: Validate environment
if not exist "%PERL%" (
    echo [ERROR] Perl not found at "%PERL%"
    pause
    exit /b 1
)

if not exist "%OPENSSL_SOURCE%\Configure" (
    echo [ERROR] OpenSSL source not found at "%OPENSSL_SOURCE%"
    pause
    exit /b 1
)

:: =============================================
:: MAIN EXECUTION
:: =============================================

:: Build all configurations
:: call :BuildOpenSSL x86 Debug
call :BuildOpenSSL x86 Release
:: call :BuildOpenSSL x64 Debug
call :BuildOpenSSL x64 Release

echo.
echo [SUCCESS] OpenSSL built for all configurations!
echo.
echo Build directories:
dir /b "%ROOT_DIR%build"
echo.
echo Install directories:
dir /b "%ROOT_DIR%install"

pause
goto :EOF

:: Function to build OpenSSL
:BuildOpenSSL
setlocal
set "PLATFORM=%~1"
set "CONFIG=%~2"

if not defined PLATFORM (
    echo [ERROR] Platform parameter not passed to BuildOpenSSL
    endlocal
    pause
    exit /b 1
)

if not defined CONFIG (
    echo [ERROR] Config parameter not passed to BuildOpenSSL
    endlocal
    pause
    exit /b 1
)

echo.
echo [INFO] Configuring OpenSSL for %PLATFORM%-%CONFIG%

:: Set directories
set "BUILD_DIR=%ROOT_DIR%build\%PLATFORM%-%CONFIG%"
set "INSTALL_DIR=%ROOT_DIR%install\%PLATFORM%-win"

:: Create directories
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

:: Configure OpenSSL
cd /d "%OPENSSL_SOURCE%"

:: Call VS environment with correct architecture
if "%PLATFORM%"=="x86" (
    call %VS_VCVARS% x86
    set "OSSL_PLATFORM=VC-WIN32"
) else if "%PLATFORM%"=="x64" (
    call %VS_VCVARS% x64
    set "OSSL_PLATFORM=VC-WIN64A"
) else (
    echo [ERROR] Unknown platform: %PLATFORM%
    endlocal
    pause
    exit /b 1
)

if "%CONFIG%"=="Debug" (
    set "OSSL_PLATFORM=!OSSL_PLATFORM! --debug"
)

:: Configure options
set "CONFIGURE_OPTS=no-shared no-pinshared no-tests %OSSL_PLATFORM% --prefix="%INSTALL_DIR%" --openssldir="%INSTALL_DIR%""
echo [INFO] Configure options of %PLATFORM%-%CONFIG% is: %CONFIGURE_OPTS%

:: Add NASM to PATH if found
if exist "%NASM%" (
    set "PATH=%PATH%;%NASM%"
)

%PERL% Configure !CONFIGURE_OPTS!

if errorlevel 1 (
    echo [ERROR] Configure failed for %PLATFORM%-%CONFIG%
    endlocal
    pause
    exit /b 1
)

set CL=/MP

:: Build
echo [INFO] Building OpenSSL for %PLATFORM%-%CONFIG%...
nmake clean >nul 2>&1
nmake build_sw

if errorlevel 1 (
    echo [ERROR] Build failed for %PLATFORM%-%CONFIG%
    endlocal
    pause
    exit /b 1
)

:: Install
echo [INFO] Installing OpenSSL for %PLATFORM%-%CONFIG%...
nmake install_sw

if errorlevel 1 (
    echo [ERROR] Install failed for %PLATFORM%-%CONFIG%
    endlocal
    pause
    exit /b 1
)

:: Rename debug libraries
if "%CONFIG%"=="Debug" (
    echo [INFO] Adding 'd' postfix to debug libraries...
    cd /d "%INSTALL_DIR%\lib" 2>nul && (
        ren "libcrypto.lib" "libcryptod.lib" 2>nul
        ren "libssl.lib" "libssld.lib" 2>nul
        if exist "libcrypto-static.lib" ren "libcrypto-static.lib" "libcrypto-staticd.lib" 2>nul
        if exist "libssl-static.lib" ren "libssl-static.lib" "libssl-staticd.lib" 2>nul
    )
)

echo [SUCCESS] OpenSSL built for %PLATFORM%-%CONFIG%
endlocal

goto :EOF