import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

BaseMenu {
    id: root
    title: qsTr("Power options")
    
    signal backRequested
    signal exitRequested
    signal rebootRequested
    signal shutdownRequested

    MenuButton {
        text: qsTr("Exit Application")
        onClicked: root.exitRequested()
    }

    MenuButton {
        text: qsTr("Reboot System")
        onClicked: root.rebootRequested()
    }

    MenuButton {
        text: qsTr("Shutdown System")
        onClicked: root.shutdownRequested()
    }

    MenuButton {
        text: qsTr("Back to Menu")
        onClicked: root.backRequested()
    }
}
