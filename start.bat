@echo off

if exist "build\windows\wallet.exe" (
 build\windows\wallet.exe
) else (
 echo Error: Application not found. Please build the project first by running:
 echo build.bat
 exit /b 1
)
