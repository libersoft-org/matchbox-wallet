#!/bin/bash
set -x
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

cd "$(dirname "$0")"

is_installed() {
 dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}
PACKAGES=("libqt6core6t64" "libqt6gui6" "libqt6qml6" "libqt6quick6" "libqt6multimedia6" "libqt6multimediawidgets6" "libqt6svg6" "libqt6svgwidgets6" "fonts-droid-fallback" "qml6-module-qtquick" "qml6-module-qtquick-controls" "qml6-module-qtquick-templates" "qml6-module-qtquick-window" "qml6-module-qtquick-layouts" "qml6-module-qtqml-workerscript" "qml6-module-qtmultimedia" "qml6-module-qtquick-localstorage" "qml6-module-qtquick-virtualkeyboard" "qml6-module-qt-labs-folderlistmodel" "libdrm2" "libgbm1" "libgl1-mesa-dri" "qt6-wayland" "ufw" "gstreamer1.0-plugins-base" "gstreamer1.0-plugins-good" "gstreamer1.0-plugins-bad" "gstreamer1.0-plugins-ugly" "gstreamer1.0-libav" "gstreamer1.0-tools")
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
fi

# Ensure ethers is available at runtime (install JS deps if missing)
echo "Installing JS dependencies in src/js before start..."
(cd src/js && npm install) || echo "Warning: npm install failed; runtime may miss modules"

if [ -f "build/linux/wallet" ]; then
	echo "Starting the application..."
	./build/linux/wallet
else
	echo "Error: Application not found. Please build the project first by running:"
	echo "./build.sh"
	exit 1
fi
