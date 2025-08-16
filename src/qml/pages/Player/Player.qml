import QtQuick 2.15
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.player.title")
	property var goPageFunction
	property var playerLocalComponent
	property var playerNetworkComponent

	MenuButton {
		text: tr("menu.player.open_local")
		onClicked: {
			if (goPageFunction && playerLocalComponent) {
				goPageFunction(playerLocalComponent);
			}
		}
	}

	MenuButton {
		text: tr("menu.player.open_network")
		onClicked: {
			if (goPageFunction && playerNetworkComponent) {
				goPageFunction(playerNetworkComponent);
			}
		}
	}
}
