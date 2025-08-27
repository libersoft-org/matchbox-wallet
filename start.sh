#!/bin/bash
#set -x
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

cd "$(dirname "$0")"

is_installed() {
 # Handle packages with variant names or distribution differences
 case "$1" in
  "libqt6gui6")
   dpkg -l "$1" 2>/dev/null | grep -q "^ii" || dpkg -l "libqt6gui6t64" 2>/dev/null | grep -q "^ii"
   ;;
  "libnode115")
   dpkg -l "$1" 2>/dev/null | grep -q "^ii" || dpkg -l "libnode109" 2>/dev/null | grep -q "^ii"
   ;;
  "qt6-svg-plugins")
   # Check for the package itself or equivalent functionality via libqt6svg6
   dpkg -l "$1" 2>/dev/null | grep -q "^ii" || dpkg -l "libqt6svg6" 2>/dev/null | grep -q "^ii"
   ;;
  *)
   dpkg -l "$1" 2>/dev/null | grep -q "^ii"
   ;;
 esac
}
PACKAGES=("libqt6core6t64" "libqt6gui6" "libqt6qml6" "libqt6quick6" "libqt6multimedia6" "libqt6multimediawidgets6" "libqt6svg6" "libqt6svgwidgets6" "qt6-svg-plugins" "fonts-droid-fallback" "qml6-module-qtquick" "qml6-module-qtquick-controls" "qml6-module-qtquick-templates" "qml6-module-qtquick-window" "qml6-module-qtquick-layouts" "qml6-module-qtqml-workerscript" "qml6-module-qtmultimedia" "qml6-module-qtquick-localstorage" "qml6-module-qtquick-virtualkeyboard" "qml6-module-qt-labs-folderlistmodel" "libdrm2" "libgbm1" "libgl1-mesa-dri" "qt6-wayland" "ufw" "gstreamer1.0-plugins-base" "gstreamer1.0-plugins-good" "gstreamer1.0-plugins-bad" "gstreamer1.0-plugins-ugly" "gstreamer1.0-libav" "gstreamer1.0-tools" "libnode115" "brightnessctl")
MISSING_PACKAGES=()
for package in "${PACKAGES[@]}"; do
 if ! is_installed "$package"; then
  MISSING_PACKAGES+=("$package")
  echo "Missing: $package"
 fi
done
if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
 echo "Installing missing packages one by one..."
 echo "Updating package lists..."
 if ! sudo apt update; then
  echo "Warning: apt update failed, but continuing with installation attempts..."
 fi
 for package in "${MISSING_PACKAGES[@]}"; do
  echo "Installing: $package"
  if ! sudo apt install -y "$package"; then
   echo "Warning: Failed to install $package, but continuing..."
  fi
 done
fi

if [ -f "build/linux/wallet" ]; then
	echo "Starting the application..."
	
	# Detect which Qt version the binary is actually linked against
	QT_LINKED_VERSION=$(ldd build/linux/wallet 2>/dev/null | grep -o 'libQt6Core\.so\.[0-9]*' | head -1)
	if [ -n "$QT_LINKED_VERSION" ]; then
		# Try to get version from the linked library
		QT_LIB_PATH=$(ldd build/linux/wallet 2>/dev/null | grep libQt6Core | awk '{print $3}' | head -1)
		if [ -f "$QT_LIB_PATH" ]; then
			# Check if it's from Qt SDK (contains version info in path)
			if echo "$QT_LIB_PATH" | grep -q "/Qt/[0-9]"; then
				QT_VERSION=$(echo "$QT_LIB_PATH" | grep -o "/Qt/[0-9.]*/" | sed 's|/Qt/||; s|/||')
				echo "Binary linked against Qt SDK version: $QT_VERSION"
			else
				SYSTEM_QT_VERSION=$(qmake6 -query QT_VERSION 2>/dev/null || echo 'unknown')
				echo "Binary linked against system Qt version: $SYSTEM_QT_VERSION"
			fi
		fi
	fi
	
	./build/linux/wallet
else
	echo "Error: Application not found. Please build the project first by running:"
	echo "  ./build.sh                    # Standard build"
	echo "  ./build-with-qt-sdk.sh        # Build with Qt SDK"
	echo "  ./build-with-felgo-live.sh    # Build with Felgo Live support"
	exit 1
fi
