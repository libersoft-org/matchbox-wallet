#!/bin/bash

echo "Checking dependencies..."
is_installed() {
 dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

PACKAGES=("cmake" "qt6-base-dev" "qt6-declarative-dev" "qt6-declarative-dev-tools" "qt6-multimedia-dev" "qt6-svg-dev" "qml6-module-qtquick" "qml6-module-qtmultimedia" "libnode-dev" "curl" "unzip")
# "clang-format")

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
cmake ../.. -DCMAKE_BUILD_TYPE=Release -DENABLE_NODEJS=ON
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
