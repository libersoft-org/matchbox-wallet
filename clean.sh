#!/bin/bash

# Remove build directory
rm -rf ./build/

# Get organization and application names from the source code
ORG_NAME=$(grep -oP 'setOrganizationName\("\K[^"]+' src/main.cpp 2>/dev/null)
APP_NAME=$(grep -oP 'setApplicationName\("\K[^"]+' src/main.cpp 2>/dev/null)

if [ -n "$ORG_NAME" ]; then
    echo "Cleaning application settings and data for organization: $ORG_NAME"
    echo "Application name: $APP_NAME"
    
    # Remove application settings and data
    rm -rf ~/.config/"$ORG_NAME"/
    rm -rf ~/.local/share/"$ORG_NAME"/
    rm -rf ~/.cache/"$ORG_NAME"/
    
    echo "Removed configuration, data and cache directories for $ORG_NAME"
else
    echo "Warning: Could not determine organization name from source code"
fi

echo "Clean complete!"
