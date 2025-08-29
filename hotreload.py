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
        self.last_reload = {}  # Track last reload time per file
        self.debounce_time = 1.0  # 1 second debounce
        
    def _handle_qml_change(self, event, event_type):
        if event.is_directory:
            return
            
        # Only watch QML files
        if not event.src_path.endswith('.qml'):
            return
            
        # Skip temporary/backup files
        filename = os.path.basename(event.src_path)
        if filename.startswith('.') or filename.endswith('~') or filename.endswith('.tmp'):
            return
            
        # Debounce: ignore rapid successive changes to the same file
        current_time = time.time()
        if event.src_path in self.last_reload:
            if current_time - self.last_reload[event.src_path] < self.debounce_time:
                return
        
        self.last_reload[event.src_path] = current_time
        print(f"QML file {event_type}: {event.src_path}")
        self.send_reload_signal(event.src_path)

    def on_modified(self, event):
        self._handle_qml_change(event, "modified")
        
    def on_moved(self, event):
        # Handle atomic saves (temp file -> target file)
        if hasattr(event, 'dest_path'):
            # Create a mock event for the destination
            class MockEvent:
                def __init__(self, path):
                    self.src_path = path
                    self.is_directory = False
            self._handle_qml_change(MockEvent(event.dest_path), "moved")
        
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
    print("🔄 Running in continuous loop - will keep trying to connect")
    
    observer = None
    
    try:
        while True:
            # Test connection to Qt app
            try:
                test_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                test_sock.settimeout(20.0)
                test_sock.connect(socket_path)
                print("✅ Successfully connected to Qt app!")
                test_sock.close()
                
                # Start observer if not already running
                if observer is None or not observer.is_alive():
                    if observer is not None:
                        observer.stop()
                        observer.join()
                    
                    event_handler = QMLReloadHandler(socket_path)
                    observer = Observer()
                    observer.schedule(event_handler, qml_dir, recursive=True)
                    observer.start()
                    print("🔥 Hot reload watcher active - edit QML files to trigger reloads")
                
            except Exception as e:
                if observer is not None and observer.is_alive():
                    print(f"❌ Lost connection to Qt app: {e}")
                    observer.stop()
                    observer.join()
                    observer = None
                    print("📱 Waiting for Qt app to restart...")
                else:
                    print(f"⏳ Waiting for Qt app to start... ({e})")
            
            time.sleep(5)  # Check every 5 seconds
            
    except KeyboardInterrupt:
        print("\nStopping hot reload watcher...")
        if observer is not None and observer.is_alive():
            observer.stop()
            observer.join()

if __name__ == "__main__":
    main()