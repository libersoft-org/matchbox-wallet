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

REM Add Qt6 MinGW to PATH if not already there
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
cmake ..\.. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
if %errorlevel% neq 0 (
 echo CMAKE configuration failed!
 echo This usually means:
 echo - Qt6 MinGW is not properly installed
 echo - MinGW compiler is not in PATH
 echo - CMake cannot find Qt6
 cd ..\..
 exit /b 1
)

echo Building with %NUMBER_OF_PROCESSORS% parallel jobs...
cmake --build . --config Release --parallel %NUMBER_OF_PROCESSORS%
if %errorlevel% neq 0 (
 echo Build failed!
 echo This usually means:
 echo - Missing MinGW compiler
 echo - Missing Qt6 dependencies
 cd ..\..
 exit /b 1
)

cd ..\..
echo Build complete!
echo Run with: .\start.bat
