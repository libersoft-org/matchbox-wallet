@echo off

echo Building Yellow Matchbox Wallet...
if exist build (
 rmdir /s /q build
)
if not exist build mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

echo Build complete!
echo Run with: build\windows\wallet.exe
