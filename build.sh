#!/bin/bash

echo "Building Yellow Matchbox Wallet..."
if [ -d "build" ]; then
 rm -rf build
fi
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
echo "Build complete!"
echo "Run with: ./build/wallet"
