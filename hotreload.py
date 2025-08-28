#!/usr/bin/env python3
"""
Simple hot reload watcher for QML files.
Watches for changes and sends reload signal to the Qt app.
"""

import os
import sys
import time
import socket
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class QMLReloadHandler(FileSystemEventHandler):
    def __init__(self, socket_path):
        self.socket_path = socket_path
        
    def on_modified(self, event):
        if event.is_directory:
            return
            
        # Only watch QML files
        if not event.src_path.endswith('.qml'):
            return
            
        print(f"QML file changed: {event.src_path}")
        self.send_reload_signal(event.src_path)
        
    def send_reload_signal(self, file_path):
        try:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.settimeout(5.0)  # 5 second timeout
            sock.connect(self.socket_path)
            
            # Send file path for potential smart reloading
            message = f"file:{file_path}".encode('utf-8')
            sock.send(message)
            
            response = sock.recv(1024)
            print(f"Response: {response.decode('utf-8')}")
            sock.close()
            
        except Exception as e:
            print(f"Failed to send reload signal: {e}")

def main():
    if len(sys.argv) > 1:
        qml_dir = sys.argv[1]
    else:
        qml_dir = "src/qml"
        
    if not os.path.exists(qml_dir):
        print(f"QML directory not found: {qml_dir}")
        sys.exit(1)
        
    socket_path = "/tmp/wallet_hotreload_12345"  # QLocalServer creates socket in /tmp/ on Linux
    
    print(f"Watching QML files in: {qml_dir}")
    print(f"Socket path: {socket_path}")
    
    # Test connection to Qt app
    try:
        test_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        test_sock.settimeout(2.0)
        test_sock.connect(socket_path)
        print("✅ Successfully connected to Qt app!")
        test_sock.close()
    except Exception as e:
        print(f"❌ Failed to connect to Qt app: {e}")
        print("Make sure the Qt wallet app is running with hot reload enabled")
        return
    
    event_handler = QMLReloadHandler(socket_path)
    observer = Observer()
    observer.schedule(event_handler, qml_dir, recursive=True)
    observer.start()
    
    print("🔥 Hot reload watcher active - edit QML files to trigger reloads")
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        print("\nStopping hot reload watcher...")
        
    observer.join()

if __name__ == "__main__":
    main()