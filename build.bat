@echo off

echo Building Yellow Matchbox Wallet...

REM Check if CMake is available
where cmake >nul 2>&1
if %errorlevel% neq 0 (
 echo Error: CMake is not installed or not in PATH!
 echo Please install CMake from: https://cmake.org/download/
 echo Make sure to add CMake to your PATH during installation.
 exit /b 1
)

REM Check if Qt6 is available
where qmake >nul 2>&1
if %errorlevel% neq 0 (
 echo Warning: Qt6 might not be properly installed or not in PATH!
 echo Please install Qt6 from: https://www.qt.io/download
 echo Make sure Qt6 bin directory is in your PATH.
 echo Continuing anyway...
)

if exist build (
 rmdir /s /q build
)
if not exist build md build
if not exist build\windows md build\windows
cd build\windows
cmake ..\.. -DCMAKE_BUILD_TYPE=Release
if %errorlevel% neq 0 (
 echo CMAKE configuration failed!
 echo This usually means:
 echo - Qt6 is not properly installed
 echo - Qt6 is not in PATH
 echo - Missing Visual Studio Build Tools
 cd ..\..
 exit /b 1
)

cmake --build . --config Release
if %errorlevel% neq 0 (
 echo Build failed!
 echo This usually means:
 echo - Missing compiler (Visual Studio Build Tools)
 echo - Missing dependencies
 cd ..\..
 exit /b 1
)

cd ..\..
echo Build complete!
echo Run with: .\start.bat
