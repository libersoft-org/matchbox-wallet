#!/bin/bash

is_installed() {
 dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}
PACKAGES=("libqt6core6" "libqt6gui6" "libqt6qml6" "libqt6quick6" "libgl1-mesa-glx" "libegl1-mesa")
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
fi
if [ -f "build/linux/wallet" ]; then
	if [ -n "$DISPLAY" ] && command -v xset >/dev/null 2>&1 && xset q >/dev/null 2>&1; then
		export QT_QPA_PLATFORM=xcb
		echo "Using X11 (xcb) platform"
	elif [ -n "$WAYLAND_DISPLAY" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
		export QT_QPA_PLATFORM=wayland
		echo "Using Wayland platform"
	elif [ -e "/dev/fb0" ] || [ -e "/dev/fb" ]; then
		export QT_QPA_PLATFORM=linuxfb
		export QT_QPA_FB="/dev/fb0"
		echo "Using Linux Framebuffer (console mode)"
	else
		export QT_QPA_PLATFORM=xcb
		echo "No display detected, trying X11 (xcb) as fallback"
	fi
	./build/linux/wallet
else
	echo "Error: Application not found. Please build the project first by running:"
	echo "./build.sh"
	exit 1
fi
