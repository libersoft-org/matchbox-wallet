import "../../components"

BaseMenu {
	id: root
	property string title: tr("player.title")

	MenuButton {
		text: tr("player.local")
		onClicked: window.goPage('Player/PlayerLocal.qml')
	}

	MenuButton {
		text: tr("player.local")
		onClicked: window.goPage('Player/PlayerLocal.qml')
	}

	MenuButton {
		text: tr("player.folder")
		onClicked: window.goPage('Player/PlayerFolder.qml')
	}

	MenuButton {
		text: tr("player.network")
		onClicked: window.goPage('Player/PlayerNetwork.qml')
	}
}
