import "../../components"

BaseMenu {
	id: root
	title: tr("player.title")

	MenuButton {
		text: tr("player.local")
		onClicked: window.goPage('Player/PlayerLocal.qml')
	}

	MenuButton {
		text: tr("player.network")
		onClicked: window.goPage('Player/PlayerNetwork.qml')
	}
}
