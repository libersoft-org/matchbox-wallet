import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	title: qsTr("System Settings")
	signal wifiSettingsRequested

	MenuButton {
		text: qsTr("WiFi")
		onClicked: root.wifiSettingsRequested();
	}

	MenuButton {
		text: qsTr("LoRa")
		enabled: false
		onClicked: console.log("LoRa settings clicked - not implemented yet");
	}
}
