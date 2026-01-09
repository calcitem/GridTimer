@echo off
REM Fast Windows Build Script for Grid Timer
REM This script uses optimized settings for faster incremental builds

setlocal EnableDelayedExpansion

REM Get script directory and project root
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
cd /d "%PROJECT_ROOT%"

REM Parse arguments
set "BUILD_MODE=debug"
set "CLEAN_BUILD=0"
set "USE_NINJA=0"

:parse_args
if "%~1"=="" goto :end_parse
if /i "%~1"=="--release" set "BUILD_MODE=release"
if /i "%~1"=="--profile" set "BUILD_MODE=profile"
if /i "%~1"=="--clean" set "CLEAN_BUILD=1"
if /i "%~1"=="--ninja" set "USE_NINJA=1"
if /i "%~1"=="--help" goto :show_help
shift
goto :parse_args
:end_parse

echo.
echo ========================================
echo   Grid Timer Fast Build
echo   Mode: %BUILD_MODE%
echo   Clean: %CLEAN_BUILD%
echo   Ninja: %USE_NINJA%
echo ========================================
echo.

REM Clean build if requested
if "%CLEAN_BUILD%"=="1" (
    echo [1/4] Cleaning build directory...
    if exist "build\windows" rmdir /s /q "build\windows"
    if exist ".dart_tool\flutter_build" rmdir /s /q ".dart_tool\flutter_build"
) else (
    echo [1/4] Skipping clean (incremental build)
)

REM Set environment for faster builds
echo [2/4] Setting up build environment...
set "FLUTTER_BUILD_MODE=%BUILD_MODE%"

REM Skip shader compilation if already done (speeds up subsequent builds)
if exist "build\flutter_assets\shaders" (
    echo       - Shader cache found, will use cached shaders
)

REM Run flutter build with optimizations
echo [3/4] Running Flutter build...
echo.

if "%USE_NINJA%"=="1" (
    REM Using Ninja generator (requires Ninja to be installed)
    REM Install via: winget install Ninja-build.Ninja
    echo Using Ninja build system...

    REM Configure with Ninja
    set "CMAKE_GENERATOR=Ninja"
    flutter build windows --%BUILD_MODE%
) else (
    REM Standard MSBuild with parallel compilation
    REM /m enables parallel project builds, /p:CL_MPCount sets compiler parallelism
    set "MSBUILD_ARGS=/m /p:CL_MPCount=%NUMBER_OF_PROCESSORS%"
    flutter build windows --%BUILD_MODE%
)

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Build failed with error code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo.
echo [4/4] Build completed successfully!
echo       Output: build\windows\x64\runner\%BUILD_MODE%\grid_timer.exe
echo.
goto :eof

:show_help
echo Usage: fast-build.bat [options]
echo.
echo Options:
echo   --debug    Build in debug mode (default)
echo   --release  Build in release mode
echo   --profile  Build in profile mode
echo   --clean    Clean build (removes build cache)
echo   --ninja    Use Ninja build system (faster, requires Ninja installed)
echo   --help     Show this help message
echo.
echo Examples:
echo   fast-build.bat                    # Debug incremental build
echo   fast-build.bat --release          # Release incremental build
echo   fast-build.bat --clean --debug    # Clean debug build
echo   fast-build.bat --ninja --release  # Release build with Ninja
echo.
echo Tips for faster builds:
echo   1. Run setup-defender-exclusions.ps1 as admin to exclude from antivirus
echo   2. Use SSD for project and Flutter SDK
echo   3. Install Ninja: winget install Ninja-build.Ninja
echo   4. Close unnecessary applications to free up RAM
echo.
goto :eof
