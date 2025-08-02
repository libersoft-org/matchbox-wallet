import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../components"

BaseMenu {
	id: root
	title: qsTr("Power options")
	
	property var goBackFunction
	property SystemManager systemManager: SystemManager { }
	
	MenuButton {
		text: qsTr("Exit application")
		onClicked: Qt.quit()
	}

	MenuButton {
		text: qsTr("Reboot")
		onClicked: systemManager.rebootSystem()
	}

	MenuButton {
		text: qsTr("Power off")
		onClicked: systemManager.shutdownSystem()
	}

	MenuButton {
		text: qsTr("Back")
		onClicked: goBackFunction()
	}
}
