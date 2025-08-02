import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	title: qsTr("Settings")
	
	signal backRequested
	signal systemSettingsRequested

	MenuButton {
		text: qsTr("Wallet")
		enabled: false
		onClicked: {
			console.log("Wallets settings clicked - not implemented yet");
		}
	}

	MenuButton {
		text: qsTr("System")
		onClicked: root.systemSettingsRequested();
	}

	MenuButton {
		text: qsTr("Back")
		onClicked: root.backRequested();
	}
}
