import "../../components"

BaseMenu {
	id: root
	property string title: tr("radio.title")

	MenuButton {
		text: tr("radio.favs.button")
		onClicked: window.goPage('Radio/RadioFavs.qml')
	}


	MenuButton {
		text: tr("radio.search.button")
		onClicked: window.goPage('Radio/RadioSearch.qml')
	}

	MenuButton {
		text: tr("radio.country.button")
		onClicked: window.goPage('Radio/RadioCountry.qml')
	}

	MenuButton {
		text: tr("radio.language.button")
		onClicked: window.goPage('Radio/RadioLang.qml')
	}
}
