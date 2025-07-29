#!/bin/bash

if [ -f "build/MainMenuApp" ]; then
	export QT_QPA_PLATFORM=xcb
	./build/wallet
else
	echo "Error: MainMenuApp not found. Please build the project first by running:"
	echo "./build.sh"
	exit 1
fi
