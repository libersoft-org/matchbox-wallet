#!/bin/bash

echo "Checking dependencies for ARM64 cross-compilation..."
is_installed() {
 dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}
PACKAGES=(
 "cmake" 
 "g++-aarch64-linux-gnu"
 "qt6-base-dev:arm64"
 "qt6-declarative-dev:arm64"
 "qt6-multimedia-dev:arm64"
 "libgstreamer1.0-dev:arm64"
 "libgstreamer-plugins-base1.0-dev:arm64"
 "libgl1-mesa-dev:arm64"
 "libegl1-mesa-dev:arm64"
 "libgles2-mesa-dev:arm64"
 "libgl-dev:arm64"
)
MISSING_PACKAGES=()
echo "Enabling ARM64 architecture..."
if ! dpkg --print-foreign-architectures | grep -q arm64; then
 echo "Adding arm64 architecture..."
 dpkg --add-architecture arm64
 apt update
fi
for package in "${PACKAGES[@]}"; do
	if ! is_installed "$package"; then
		MISSING_PACKAGES+=("$package")
		echo "Missing: $package"
	fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
 echo "Installing missing packages: ${MISSING_PACKAGES[*]}"
 apt update && apt install -y "${MISSING_PACKAGES[@]}"
else
 echo "All dependencies are already installed."
fi

echo "Building Matchbox Wallet for ARM64..."
if [ -d "build" ]; then
 rm -rf build
fi
mkdir -p build/linux
cd build/linux

# Configure with CMake for ARM64 cross-compilation
cmake ../.. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=../../arm64-toolchain.cmake

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
