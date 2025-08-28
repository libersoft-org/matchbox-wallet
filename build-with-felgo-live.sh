#!/bin/bash

# Convenience script to build with Felgo Live support
FELGO_SDK_ROOT=${FELGO_SDK_ROOT:-~/Felgo}
# Expand tilde to full path
FELGO_SDK_ROOT=$(eval echo "$FELGO_SDK_ROOT")
export FELGO_SDK_ROOT

# Check if Felgo SDK is available
if [ ! -d "$FELGO_SDK_ROOT" ]; then
    echo "Felgo SDK not found at $FELGO_SDK_ROOT"
    echo "Please install Felgo SDK or set FELGO_SDK_ROOT environment variable"
    echo "Download from: https://felgo.com/download"
    exit 1
fi

echo "Building with Felgo Live support"
echo "Felgo SDK: $FELGO_SDK_ROOT"

# Add Felgo paths - point to the gcc_64 subdirectory where CMake files are located
FELGO_CMAKE_PATH="$FELGO_SDK_ROOT/Felgo/gcc_64"
export CMAKE_PREFIX_PATH="$FELGO_CMAKE_PATH:$CMAKE_PREFIX_PATH"
export PATH="$FELGO_SDK_ROOT/bin:$PATH"

# Set Felgo Hot Reload environment variables
export FELGO_HOT_RELOAD_PATH="$FELGO_CMAKE_PATH"
export FELGO_PROJECT_PATH="$(pwd)"

echo "Felgo CMake path: $FELGO_CMAKE_PATH"

# Enable Felgo Live in CMake
export CMAKE_ARGS="-DENABLE_FELGO_LIVE=ON $CMAKE_ARGS"

echo "CMake arguments: $CMAKE_ARGS"

# Run the main build script with Felgo Live enabled
./build.sh

# Setup QML sources for Felgo Hot Reload
echo "Setting up QML sources for Felgo Live..."

# Create symlink so the app can find sources from its working directory  
ln -sf ../../src build/linux/src

# Replace CMake's copied sources with symlinks to originals in WalletModule
rm -rf build/linux/WalletModule/src
ln -sf "$(pwd)/src" build/linux/WalletModule/src

echo "✅ QML sources symlinked - Felgo will hot reload original source files"