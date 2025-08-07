import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.settings.system.language.title")

	signal languageSelected(string languageCode)

	MenuButton {
		id: englishButton
		text: tr("common.languages.english")
		onClicked: {
			root.languageSelected("en");
		}
	}

	MenuButton {
		id: czechButton
		text: tr("common.languages.czech")
		onClicked: {
			root.languageSelected("cz");
		}
	}
}
