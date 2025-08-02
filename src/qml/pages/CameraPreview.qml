import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 6.0
import WalletModule 1.0
import "../components"

Rectangle {
    id: root
    color: "#000000"
    property string title: qsTr("Camera Preview")
    
    signal backRequested
    signal powerOffRequested
    
    // Camera and capture session for Qt6
    CaptureSession {
        id: captureSession
        camera: Camera {
            id: camera
            active: false
            
            onActiveChanged: {
                console.log("Camera active state changed to:", active)
            }
            
            onErrorOccurred: function(error, errorString) {
                console.error("Camera error:", error, errorString)
                errorText.text = "Camera error: " + errorString
                errorText.visible = true
            }
        }
        videoOutput: videoOutput
    }
    
    // Video output for live preview
    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        anchors.margins: 10
        
        // Show loading indicator when camera is starting
        Rectangle {
            id: loadingIndicator
            anchors.centerIn: parent
            width: 100
            height: 100
            color: "#33ffffff"
            radius: 10
            visible: !camera.active && !errorText.visible
            
            BusyIndicator {
                anchors.centerIn: parent
                running: parent.visible
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                text: "Starting camera..."
                color: "white"
                font.pointSize: 12
            }
        }
    }
    
    // Error message
    Text {
        id: errorText
        anchors.centerIn: parent
        text: "Camera not available"
        color: "red"
        font.pointSize: 16
        font.bold: true
        visible: false
    }
   
    
    // Camera controls
    Rectangle {
        id: bottomOverlay
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80
        color: "#80000000"
        
        RowLayout {
            anchors.centerIn: parent
            spacing: 20
            
            // Start/Stop camera button
            Button {
                id: toggleButton
                text: camera.active ? "Stop Camera" : "Start Camera"
                font.pointSize: 14
                Layout.preferredWidth: 150
                Layout.preferredHeight: 50
                
                background: Rectangle {
                    color: camera.active ? 
                           (parent.pressed ? "#cc4444" : "#ff6666") : 
                           (parent.pressed ? "#44cc44" : "#66ff66")
                    radius: 5
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    if (camera.active) {
                        camera.active = false
                    } else {
                        camera.active = true
                        errorText.visible = false
                    }
                }
            }
            
            // Camera info
            Text {
                text: "Raspberry Pi Camera Module 3"
                color: "white"
                font.pointSize: 12
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
    
    // Handle cleanup when component is destroyed
    Component.onDestruction: {
        if (camera.active) {
            camera.active = false
        }
    }
    
    // Initialize camera on component completion
    Component.onCompleted: {
        console.log("Initializing camera...")
        // Give a small delay to ensure the component is fully loaded
        timer.start()
    }
    
    Timer {
        id: timer
        interval: 500
        onTriggered: {
            console.log("Starting camera...")
            camera.active = true
        }
    }
}