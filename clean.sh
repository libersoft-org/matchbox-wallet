#!/bin/bash

echo "Cleaning temporary QML formatting files..."
find . -name "*-formatting-tmp.qml~" -type f -delete
REMOVED=$(find . -name "*-formatting-tmp.qml~" -type f | wc -l)
echo "All temporary files cleaned!"
