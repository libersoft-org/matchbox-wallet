#!/bin/bash

echo "Checking dependencies..."
is_installed() {
 dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}
PACKAGES=("cmake" "qt6-base-dev" "qt6-declarative-dev")
MISSING_PACKAGES=()
for package in "${PACKAGES[@]}"; do
 if ! is_installed "$package"; then
  MISSING_PACKAGES+=("$package")
  echo "Missing: $package"
 else
  echo "Already installed: $package"
 fi
done
if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
 echo "Installing missing packages: ${MISSING_PACKAGES[*]}"
 apt update && apt install -y "${MISSING_PACKAGES[@]}"
else
 echo "All dependencies are already installed."
fi
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
echo "Run with: ./start.sh"
