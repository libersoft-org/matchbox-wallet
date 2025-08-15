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

# Install Bun for JavaScript/TypeScript building
echo "Setting up Bun runtime..."
if ! command -v bun >/dev/null 2>&1; then
 echo "Installing Bun..."
 curl -fsSL https://bun.sh/install | bash || {
  echo "Failed to install Bun."
  exit 1
 }
 # Add bun to PATH for current session
 export PATH="$HOME/.bun/bin:$PATH"
fi

# Build JavaScript bundle for embedded Node runtime
if [ -d "src/js" ]; then
 echo "Building JavaScript/TypeScript bundle..."
 (cd src/js && bun install) || {
  echo "bun install failed in src/js"
  exit 1
 }
 (cd src/js && bun run build) || {
  echo "JavaScript build failed"
  exit 1
 }
 # Verify bundle was created
 if [ ! -f "src/js/dist/bundle.cjs" ]; then
  echo "ERROR: JavaScript bundle was not created!"
  exit 1
 fi
 BUNDLE_SIZE=$(du -h src/js/dist/bundle.cjs | cut -f1)
 echo "✅ JavaScript bundle created: src/js/dist/bundle.cjs ($BUNDLE_SIZE)"
fi

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
