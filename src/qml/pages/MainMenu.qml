import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../components"

BaseMenu {
	id: root
	title: tr("mainMenu.title")
	property bool showBackButton: false
	property var walletComponent
	property var settingsComponent
	property var powerOffComponent  
	property var cameraPreviewComponent
	property var goPageFunction

	MenuButton {
		text: tr("mainMenu.wallet")
		onClicked: goPageFunction(walletComponent)
	}
	
	MenuButton {
		text: tr("mainMenu.settings")
		onClicked: goPageFunction(settingsComponent)
	}

	MenuButton {
		text: "Camera test"
		onClicked: goPageFunction(cameraPreviewComponent)
	}
}
