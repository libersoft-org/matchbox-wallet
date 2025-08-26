import "../../components"

BaseMenu {
	id: root
	property string title: tr("radio.menu.title")

	MenuButton {
		text: tr("radio.menu.favs")
		onClicked: window.goPage('Radio/RadioFavs.qml')
	}

	MenuButton {
		text: tr("radio.menu.search")
		onClicked: window.goPage('Radio/RadioSearch.qml')
	}

	MenuButton {
		text: tr("radio.menu.country")
		onClicked: window.goPage('Radio/RadioCountry.qml')
	}

	MenuButton {
		text: tr("radio.menu.language")
		onClicked: window.goPage('Radio/RadioLang.qml')
	}
}
