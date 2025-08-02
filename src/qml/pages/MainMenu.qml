import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

BaseMenu {
    id: root
    title: qsTr("Yellow Matchbox Wallet")
    property var settingsComponent
    property var powerOffComponent  
    property var cameraPreviewComponent
    property var goPageFunction
    
    function openSettings() {
        if (goPageFunction && settingsComponent) {
            goPageFunction(settingsComponent);
        }
    }
    
    function openPowerOff() {
        if (goPageFunction && powerOffComponent) {
            goPageFunction(powerOffComponent);
        }
    }
    
    function openCameraPreview() {
        if (goPageFunction && cameraPreviewComponent) {
            goPageFunction(cameraPreviewComponent);
        }
    }

    // Settings button
    MenuButton {
        text: qsTr("Settings")
        onClicked: root.openSettings()
    }

    MenuButton {
        text: qsTr("Test camera")
        onClicked: root.openCameraPreview()
    }

    MenuButton {
        text: qsTr("Disabled button")
        backgroundColor: "#0000ff"
        textColor: "#fff"
        enabled: false
    }

    MenuButton {
        text: qsTr("Power off")
        backgroundColor: "#880000"
        textColor: "#fff"
        onClicked: root.openPowerOff()
    }
}
