#!/bin/bash

echo "Checking dependencies..."

# Detect host architecture
HOST_ARCH=$(uname -m)
if [ "$HOST_ARCH" = "x86_64" ]; then
    ARCH_SUFFIX="amd64"
elif [ "$HOST_ARCH" = "aarch64" ]; then
    ARCH_SUFFIX="arm64"
else
    ARCH_SUFFIX=""
fi

is_installed() {
 dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Packages that should have architecture suffix
ARCH_PACKAGES=("qt6-base-dev" "qt6-declarative-dev" "qt6-multimedia-dev" "qt6-svg-dev" "qt6-tools-dev" "libnode-dev")
# Packages that don't need architecture suffix
BASE_PACKAGES=("build-essential" "cmake" "qt6-declarative-dev-tools" "qml6-module-qtquick" "qml6-module-qtmultimedia" "curl" "unzip" "python3-watchdog")

PACKAGES=("${BASE_PACKAGES[@]}")
if [ -n "$ARCH_SUFFIX" ]; then
    for pkg in "${ARCH_PACKAGES[@]}"; do
        PACKAGES+=("${pkg}:${ARCH_SUFFIX}")
    done
else
    PACKAGES+=("${ARCH_PACKAGES[@]}")
fi

MISSING_PACKAGES=()
for package in "${PACKAGES[@]}"; do
 if ! is_installed "$package"; then
  MISSING_PACKAGES+=("$package")
  echo "Missing: $package"
 fi
done
if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
 echo "Installing missing packages: ${MISSING_PACKAGES[*]}"
 sudo apt update && sudo apt install -y "${MISSING_PACKAGES[@]}"
else
 echo "All dependencies are already installed."
fi

./build-js.sh

echo "Building the application..."
if [ -d "build" ]; then
 rm -rf build
fi
mkdir -p build/linux
cd build/linux

# Set architecture-specific library paths
if [ "$HOST_ARCH" = "x86_64" ]; then
    echo "Configuring for x86_64 native build..."
    export PKG_CONFIG_LIBDIR=/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig
    CMAKE_LIBRARY_ARCH="-DCMAKE_LIBRARY_ARCHITECTURE=x86_64-linux-gnu"
elif [ "$HOST_ARCH" = "aarch64" ]; then
    echo "Configuring for aarch64 native build..."
    export PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig
    CMAKE_LIBRARY_ARCH="-DCMAKE_LIBRARY_ARCHITECTURE=aarch64-linux-gnu"
else
    echo "Warning: Unknown architecture $HOST_ARCH, proceeding without explicit library architecture"
    CMAKE_LIBRARY_ARCH=""
fi

# Configure CMake with optional Qt SDK path
BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release}
echo "Build type: $BUILD_TYPE"
CMAKE_ARGS="-DCMAKE_BUILD_TYPE=$BUILD_TYPE -DENABLE_NODEJS=ON $CMAKE_LIBRARY_ARCH $CMAKE_ARGS"

# If QT_DIR is set, use it to find Qt SDK instead of system Qt
if [ -n "$QT_DIR" ]; then
    echo "Using Qt SDK from: $QT_DIR"
    CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_PREFIX_PATH=$QT_DIR"
else
    echo "Using system Qt libraries"
fi

cmake ../.. $CMAKE_ARGS
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
echo "Run with: ./start.sh"
