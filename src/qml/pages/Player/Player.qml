import QtQuick 2.15
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.player.title")

	MenuButton {
		text: tr("menu.player.local")
		onClicked: window.goPage('Player/PlayerLocal.qml')
	}

	MenuButton {
		text: tr("menu.player.network")
		onClicked: window.goPage('Player/PlayerNetwork.qml')
	}
}
