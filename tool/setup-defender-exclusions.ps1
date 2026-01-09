# Windows Defender Exclusions for Flutter Development
# This script adds exclusions to improve build performance
# Run as Administrator: Start-Process powershell -Verb runAs -ArgumentList "-ExecutionPolicy Bypass -File setup-defender-exclusions.ps1"

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "Setting up Windows Defender exclusions for Flutter development..." -ForegroundColor Green

# Get the project root directory (parent of tool folder)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Define paths to exclude
$PathsToExclude = @(
    # Project build directories
    "$ProjectRoot\build",
    "$ProjectRoot\.dart_tool",
    "$ProjectRoot\android\.gradle",
    "$ProjectRoot\android\build-cache",

    # Flutter SDK (adjust if your Flutter is installed elsewhere)
    "C:\Flutter",
    "$env:LOCALAPPDATA\Pub\Cache",

    # Visual Studio build tools
    "$env:LOCALAPPDATA\Microsoft\VisualStudio",

    # Gradle cache
    "$env:USERPROFILE\.gradle"
)

# Define processes to exclude
$ProcessesToExclude = @(
    "dart.exe",
    "flutter.exe",
    "msbuild.exe",
    "cl.exe",
    "link.exe",
    "cmake.exe",
    "ninja.exe",
    "devenv.exe",
    "gradle.exe",
    "java.exe"
)

# Add path exclusions
Write-Host "`nAdding path exclusions:" -ForegroundColor Yellow
foreach ($path in $PathsToExclude) {
    if (Test-Path $path -ErrorAction SilentlyContinue) {
        try {
            Add-MpPreference -ExclusionPath $path
            Write-Host "  [OK] $path" -ForegroundColor Green
        } catch {
            Write-Host "  [SKIP] $path (may already exist or access denied)" -ForegroundColor DarkYellow
        }
    } else {
        Write-Host "  [SKIP] $path (path does not exist)" -ForegroundColor DarkGray
    }
}

# Add process exclusions
Write-Host "`nAdding process exclusions:" -ForegroundColor Yellow
foreach ($process in $ProcessesToExclude) {
    try {
        Add-MpPreference -ExclusionProcess $process
        Write-Host "  [OK] $process" -ForegroundColor Green
    } catch {
        Write-Host "  [SKIP] $process (may already exist)" -ForegroundColor DarkYellow
    }
}

# Add file extension exclusions for intermediate build files
$ExtensionsToExclude = @(
    ".obj",
    ".pdb",
    ".ilk",
    ".idb",
    ".dill",
    ".snapshot"
)

Write-Host "`nAdding file extension exclusions:" -ForegroundColor Yellow
foreach ($ext in $ExtensionsToExclude) {
    try {
        Add-MpPreference -ExclusionExtension $ext
        Write-Host "  [OK] $ext" -ForegroundColor Green
    } catch {
        Write-Host "  [SKIP] $ext (may already exist)" -ForegroundColor DarkYellow
    }
}

Write-Host "`n[DONE] Windows Defender exclusions configured!" -ForegroundColor Green
Write-Host "Note: You may need to restart your terminal/IDE for changes to take full effect." -ForegroundColor Cyan
