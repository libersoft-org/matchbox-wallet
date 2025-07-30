#!/bin/bash

apt update && apt install -y cmake qt6-declarative-dev

echo "Building Yellow Matchbox Wallet..."
if [ -d "build" ]; then
 rm -rf build
fi
mkdir -p build/linux
cd build/linux
cmake ../.. -DCMAKE_BUILD_TYPE=Release
if [ $? -ne 0 ]; then
 echo "CMAKE configuration failed!"
 exit 1
fi

CORES=$(nproc)
echo "Building with $CORES parallel jobs..."
cmake --build . --config Release --parallel $CORES
if [ $? -ne 0 ]; then
 echo "Build failed!"
 exit 1
fi

echo "Build complete!"
echo "Run with: ./build/linux/wallet"
