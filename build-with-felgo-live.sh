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

# Add Felgo paths
export CMAKE_PREFIX_PATH="$FELGO_SDK_ROOT:$CMAKE_PREFIX_PATH"
export PATH="$FELGO_SDK_ROOT/bin:$PATH"

# Enable Felgo Live in CMake
export CMAKE_ARGS="-DENABLE_FELGO_LIVE=ON -DCMAKE_PREFIX_PATH=$FELGO_SDK_ROOT:$CMAKE_PREFIX_PATH $CMAKE_ARGS"

echo "CMake arguments: $CMAKE_ARGS"

# Run the main build script with Felgo Live enabled
./build.sh