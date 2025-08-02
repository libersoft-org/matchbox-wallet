import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

BaseMenu {
    id: root
    title: qsTr("Yellow Matchbox Wallet")
    
    signal settingsRequested
    signal powerOffRequested
    signal cameraPreviewRequested

    // Settings button
    MenuButton {
        text: qsTr("Settings")
        onClicked: root.settingsRequested()
    }

    MenuButton {
        text: qsTr("Test camera")
        onClicked: root.cameraPreviewRequested()
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
        onClicked: root.powerOffRequested()
    }
}
