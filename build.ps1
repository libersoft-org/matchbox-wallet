#!/usr/bin/env pwsh

Write-Host "Building Matchbox Wallet..."

# Check if CMake is available
if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
	Write-Host "Error: CMake is not installed or not in PATH!"
	Write-Host "Please install CMake from: https://cmake.org/download/"
	Write-Host "Make sure to add CMake to your PATH during installation."
	exit 1
}

# Check if Qt6 is available
if (-not (Get-Command qmake -ErrorAction SilentlyContinue)) {
	Write-Host "Warning: Qt6 might not be properly installed or not in PATH!"
	Write-Host "Please install Qt6 from: https://www.qt.io/download"
	Write-Host "Make sure Qt6 bin directory is in your PATH."
	Write-Host "Continuing anyway..."
}

# Clean previous build
if (Test-Path build) {
	Remove-Item -Recurse -Force build
}

# Create build directories
New-Item -ItemType Directory -Force -Path build\windows | Out-Null
Set-Location build\windows

# Configure with CMake
cmake ..\.. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
if ($LASTEXITCODE -ne 0) {
	Write-Host "CMAKE configuration failed!"
	Write-Host "This usually means:"
	Write-Host "- Qt6 MinGW is not properly installed"
	Write-Host "- MinGW compiler is not in PATH"
	Write-Host "- CMake cannot find Qt6"
	Set-Location ..\..
	exit 1
}

# Build
Write-Host "Building with $env:NUMBER_OF_PROCESSORS parallel jobs..."
cmake --build . --config Release --parallel $env:NUMBER_OF_PROCESSORS
if ($LASTEXITCODE -ne 0) {
	Write-Host "Build failed!"
	Write-Host "This usually means:"
	Write-Host "- Missing MinGW compiler"
	Write-Host "- Missing Qt6 dependencies"
	Set-Location ..\..
	exit 1
}

Set-Location ..\..
Write-Host "Build complete!"
Write-Host "Run with: .\start.bat"
