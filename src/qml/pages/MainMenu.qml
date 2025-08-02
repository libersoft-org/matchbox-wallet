import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

BaseMenu {
    id: root
    title: qsTr("Yellow Matchbox Wallet")
    
    // Properties to hold references to components (will be set from parent)
    property var settingsComponent
    property var powerOffComponent  
    property var cameraPreviewComponent
    
    // Define functions directly in this component
    function openSettings() {
        // Get the parent StackView and push Settings page
        var stackView = root.parent;
        while (stackView && !stackView.hasOwnProperty('push')) {
            stackView = stackView.parent;
        }
        if (stackView && settingsComponent) {
            stackView.push(settingsComponent);
        }
    }
    
    function openPowerOff() {
        // Get the parent StackView and push PowerOff page
        var stackView = root.parent;
        while (stackView && !stackView.hasOwnProperty('push')) {
            stackView = stackView.parent;
        }
        if (stackView && powerOffComponent) {
            stackView.push(powerOffComponent);
        }
    }
    
    function openCameraPreview() {
        // Get the parent StackView and push CameraPreview page
        var stackView = root.parent;
        while (stackView && !stackView.hasOwnProperty('push')) {
            stackView = stackView.parent;
        }
        if (stackView && cameraPreviewComponent) {
            stackView.push(cameraPreviewComponent);
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
