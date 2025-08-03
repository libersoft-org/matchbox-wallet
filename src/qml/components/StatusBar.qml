import QtQuick 2.15
import QtQuick.Controls 2.15
import "../"

Rectangle {
    id: statusBar
    color: Qt.darker(AppConstants.primaryBackground)
    height: 32  // Default height, can be overridden by parent
    
    // Properties for connection states
    property int wifiStrength: 0    // WiFi signal strength (0-4)
    property int loraStrength: 0    // LoRa signal strength (0-4)
    property int gsmStrength: 0     // GSM signal strength (0-4)
    property int batteryLevel: 0  // Battery level (0-100)
    property bool hasBattery: false  // Whether device has battery
    property string currentTime: "00:00"
    
    // Update time
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date()
            statusBar.currentTime = Qt.formatTime(now, "hh:mm")
        }
    }
    
    Component.onCompleted: {
        var now = new Date()
        statusBar.currentTime = Qt.formatTime(now, "hh:mm")
    }
    
    Row {
        anchors.left: parent.left
        anchors.leftMargin: statusBar.height * 0.3
        anchors.verticalCenter: parent.verticalCenter
        spacing: statusBar.height * 0.25
        
        // WiFi signal
        Row {
            spacing: statusBar.height * 0.1
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: "W"
                color: AppConstants.primaryForeground
                font.pixelSize: statusBar.height * 0.4
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
            SignalStrength {
                width: statusBar.height * 0.65
                height: statusBar.height * 0.4
                strength: statusBar.wifiStrength
            }
        }
        
        // LoRa signal
        Row {
            spacing: statusBar.height * 0.1
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: "L"
                color: AppConstants.primaryForeground
                font.pixelSize: statusBar.height * 0.4
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
            SignalStrength {
                width: statusBar.height * 0.65
                height: statusBar.height * 0.4
                strength: statusBar.loraStrength
            }
        }
        
        // GSM signal
        Row {
            spacing: statusBar.height * 0.1
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: "G"
                color: AppConstants.primaryForeground
                font.pixelSize: statusBar.height * 0.4
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
            SignalStrength {
                width: statusBar.height * 0.65
                height: statusBar.height * 0.4
                strength: statusBar.gsmStrength
            }
        }
    }
    
    Row {
        anchors.right: parent.right
        anchors.rightMargin: statusBar.height * 0.3
        anchors.verticalCenter: parent.verticalCenter
        spacing: statusBar.height * 0.25
        
        // Battery icon and percentage
        Row {
            spacing: statusBar.height * 0.15
            anchors.verticalCenter: parent.verticalCenter
            
            // Battery icon
            Rectangle {
                width: statusBar.height * 0.75
                height: statusBar.height * 0.4
                color: "transparent"
                border.color: "white"
                border.width: Math.max(1, statusBar.height * 0.03)
                radius: statusBar.height * 0.06
                anchors.verticalCenter: parent.verticalCenter
                
                // Battery tip
                Rectangle {
                    width: statusBar.height * 0.06
                    height: statusBar.height * 0.2
                    color: "white"
                    anchors.left: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    radius: statusBar.height * 0.03
                }
                
                // Battery fill
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Math.max(1, statusBar.height * 0.06)
                    color: statusBar.batteryLevel > 20 ? "#080" : "#800"
                    radius: statusBar.height * 0.03
                    width: parent.width * (statusBar.batteryLevel / 100.0)
                    visible: statusBar.hasBattery
                }
                
                // Cross for no battery
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: Math.max(2, statusBar.height * 0.06)
                    color: "red"
                    rotation: 45
                    visible: !statusBar.hasBattery
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: Math.max(2, statusBar.height * 0.06)
                    color: "red"
                    rotation: -45
                    visible: !statusBar.hasBattery
                }
            }
            
            // Battery percentage
            Text {
                text: statusBar.hasBattery ? statusBar.batteryLevel + "%" : "N/A"
                color: AppConstants.primaryForeground
                font.pixelSize: statusBar.height * 0.35
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        
        // Time
        Text {
            text: statusBar.currentTime
            color: AppConstants.primaryForeground
            font.pixelSize: statusBar.height * 0.4
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
