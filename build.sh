#!/bin/bash

echo "Checking dependencies..."
is_installed() {
 dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}
PACKAGES=("cmake" "qt6-base-dev" "qt6-declarative-dev" "qt6-declarative-dev-tools" "qt6-multimedia-dev" "qt6-svg-dev" "qml6-module-qtquick" "qml6-module-qtmultimedia" "libnode-dev" "npm" "clang-format")
MISSING_PACKAGES=()
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

# Ensure JS dependencies are installed for embedded Node runtime
echo "Ensuring JavaScript dependencies..."
if ! command -v npm >/dev/null 2>&1; then
 echo "npm not found, attempting to install..."
 apt update && apt install -y npm || {
  echo "Failed to install npm."
  exit 1
 }
fi

# Install npm packages
if [ -d "src/js" ]; then
 echo "Installing npm packages in src/js..."
 (cd src/js && npm install) || {
  echo "npm install failed in src/js"
  exit 1
 }
fi

echo "Building Matchbox Wallet..."
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
echo "Run with: ./start.sh"
