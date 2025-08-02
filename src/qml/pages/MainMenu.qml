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

	MenuButton {
		text: qsTr("Settings")
		onClicked: goPageFunction(settingsComponent)
	}

	MenuButton {
		text: qsTr("Test camera")
		onClicked: goPageFunction(cameraPreviewComponent)
	}

	MenuButton {
		text: qsTr("Disabled button")
		backgroundColor: "#00f"
		textColor: "#fff"
		enabled: false
	}

	MenuButton {
		text: qsTr("Power off")
		backgroundColor: "#800"
		textColor: "#fff"
		onClicked: goPageFunction(powerOffComponent)
	}
}
