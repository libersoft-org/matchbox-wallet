#!/bin/bash

cd "$(dirname "$0")"

is_installed() {
 dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}
PACKAGES=("libqt6core6" "libqt6gui6" "libqt6qml6" "libqt6quick6" "libqt6multimedia6" "libqt6multimediawidgets6" "libqt6multimediaquick6" "libqt6svg6" "libqt6svgwidgets6" "libgl1-mesa-glx" "libegl1-mesa" "fonts-droid-fallback" "qml6-module-qtquick" "qml6-module-qtquick-controls" "qml6-module-qtquick-templates" "qml6-module-qtquick-window" "qml6-module-qtquick-layouts" "qml6-module-qtqml-workerscript" "qml6-module-qtmultimedia" "qml6-module-qtquick-localstorage" "gstreamer1.0-tools" "gstreamer1.0-plugins-base" "gstreamer1.0-plugins-good" "gstreamer1.0-plugins-bad" "gstreamer1.0-libav" "gstreamer1.0-libcamera" "libcamera-apps" "qt6-multimedia-dev")
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
	# Set up environment for QtMultimedia with Raspberry Pi camera support
	export QT_LOGGING_RULES="qt.multimedia.*=true"
	export GST_DEBUG=2
	export QT_MULTIMEDIA_PREFERRED_PLUGINS="gstreamer"
	export QT_MEDIA_BACKEND=gstreamer
	export GST_PLUGIN_PATH="/usr/lib/aarch64-linux-gnu/gstreamer-1.0"
	
	# Raspberry Pi specific GStreamer settings
	export GST_PLUGIN_FEATURE_RANK="libcamerasrc:MAX,v4l2src:MAX"
	export LIBCAMERA_LOG_LEVELS="*:WARN"
	
	# Force V4L2 device enumeration for Qt
	export QT_V4L2_DEVICE_ORDER="/dev/video0,/dev/video1,/dev/video2"
	export GST_V4L2_USE_LIBV4L2=1
	
	# Add current user to video group if not already (for camera access)
	if ! groups $USER | grep -q video; then
		echo "Adding user to video group for camera access..."
		sudo usermod -a -G video $USER
		echo "Please log out and log back in for group changes to take effect"
	fi
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
	
	# Enable QML XMLHttpRequest file reading for translations
	export QML_XHR_ALLOW_FILE_READ=1
	echo "Starting Matchbox Wallet..."
	./build/linux/wallet
else
	echo "Error: Application not found. Please build the project first by running:"
	echo "./build.sh"
	exit 1
fi
