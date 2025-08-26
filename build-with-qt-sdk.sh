#!/bin/bash

# Convenience script to build with Qt SDK instead of system Qt
export QT_DIR=/home/koom/Qt/6.9.2/gcc_64

# Add QtDesignStudio QML path for VirtualKeyboard module
export QML_IMPORT_PATH=/home/koom/Qt/Tools/QtDesignStudio/qt6_design_studio_reduced_version/qml

echo "Building with Qt SDK: $QT_DIR"
echo "QML Import Path: $QML_IMPORT_PATH"

# Run the main build script
./build.sh