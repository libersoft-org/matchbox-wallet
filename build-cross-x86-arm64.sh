#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

export PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig
export PKG_CONFIG=/usr/bin/pkg-config

echo "Checking dependencies for ARM64 cross-compilation..."
is_installed() {
 dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Install ARM64 packages in stages to avoid dependency conflicts
CORE_PACKAGES=(
 "curl"
 "cmake"
 "crossbuild-essential-arm64"
 "g++-aarch64-linux-gnu"
)

QT_PACKAGES=(
 "qt6-base-dev:arm64"
 "qt6-declarative-dev:arm64"
 "qt6-multimedia-dev:arm64"
 "qt6-svg-dev:arm64"
)

MEDIA_PACKAGES=(
 "libgstreamer1.0-dev:arm64"
 "libgstreamer-plugins-base1.0-dev:arm64"
 "libgl1-mesa-dev:arm64"
 "libegl1-mesa-dev:arm64"
 "libgles2-mesa-dev:arm64"
)

NODE_PACKAGES=(
 "libnode-dev:arm64"
)


echo "Enabling ARM64 architecture..."
if ! dpkg --print-foreign-architectures | grep -q arm64; then
 echo "Adding arm64 architecture..."
 sudo dpkg --add-architecture arm64
 sudo apt update
fi

# Install packages in stages to avoid dependency conflicts
install_packages() {
    local package_array=("$@")
    local missing_packages=()
    
    for package in "${package_array[@]}"; do
        if ! is_installed "$package"; then
            missing_packages+=("$package")
            echo "Missing: $package"
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo "Installing missing packages: ${missing_packages[*]}"
        sudo apt update && sudo apt install -y "${missing_packages[@]}"
    else
        echo "All packages in this stage are already installed."
    fi
}

echo "Installing core packages..."
install_packages "${CORE_PACKAGES[@]}"

echo "Installing Qt packages..."
install_packages "${QT_PACKAGES[@]}"

echo "Installing media packages..."
install_packages "${MEDIA_PACKAGES[@]}"

echo "Installing Node.js packages..."
install_packages "${NODE_PACKAGES[@]}"

./build-js.sh

echo "Building the application for ARM64..."
if [ -d "build" ]; then
 rm -rf build
fi
mkdir -p build/linux
cd build/linux

# Configure with CMake for ARM64 cross-compilation
cmake ../.. \
  -DNODEJS_LOG=ON \
  -DCMAKE_MESSAGE_LOG_LEVEL=DEBUG \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=../../arm64-toolchain.cmake   
#   --debug-find 


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

echo "ARM64 cross-compilation complete!"
echo "Binary location: ./build/linux/wallet"
echo "To run on ARM64 device, copy the binary and install required Qt6 libraries."

# Display binary info
if [ -f "wallet" ]; then
	echo ""
	echo "Binary information:"
	file wallet
	echo ""
	echo "Size: $(du -h wallet | cut -f1)"
fi
