#!/bin/bash

# Watch script for automatic rebuild and run

echo "Starting Qt App Watch Mode..."
echo "Watching for changes in src/ directory..."
echo "Press Ctrl+C to stop"

# Initial build
echo "Initial build..."
./build.sh

# Function to rebuild and restart app
rebuild_and_run() {
    echo ""
    echo "🔄 Changes detected! Rebuilding..."
    
    # Kill existing app if running
    pkill -f MainMenuApp 2>/dev/null
    
    # Quick rebuild (only if C++ files changed, otherwise just restart)
    if [[ "$1" == *.cpp ]] || [[ "$1" == *.h ]]; then
        echo "C++ files changed, full rebuild..."
        cd build && cmake --build . --config Release
    else
        echo "QML files changed, no rebuild needed..."
    fi
    
    # Start app in background
    echo "🚀 Starting application..."
    ./build/MainMenuApp &
    echo "Application started! (PID: $!)"
}

# Start the app initially
echo "🚀 Starting application..."
./build/MainMenuApp &
APP_PID=$!
echo "Application started! (PID: $APP_PID)"

# Watch for changes using inotifywait
if command -v inotifywait >/dev/null 2>&1; then
    # Use inotifywait if available (more efficient)
    inotifywait -m -r -e modify,create,delete --format '%w%f' src/ | while read file; do
        rebuild_and_run "$file"
    done
else
    # Fallback to simple polling
    echo "inotifywait not found, using polling method..."
    echo "Install inotify-tools for better performance: sudo apt-get install inotify-tools"
    
    LAST_CHANGE=$(find src/ -type f -newer /tmp/watch_marker 2>/dev/null | wc -l)
    touch /tmp/watch_marker
    
    while true; do
        sleep 2
        CURRENT_CHANGE=$(find src/ -type f -newer /tmp/watch_marker 2>/dev/null | wc -l)
        if [ "$CURRENT_CHANGE" -gt 0 ]; then
            touch /tmp/watch_marker
            rebuild_and_run "generic"
        fi
    done
fi
