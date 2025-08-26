import QtQuick 6.8
import "../../components"

BaseMenu {
	id: root
	property string title: tr("settings.language.title")

	function selectLanguage(languageCode) {
		window.settingsManager.saveLanguage(languageCode);
		window.translationManager.setLanguage(languageCode);
		window.goBack();
	}

	MenuButton {
		id: englishButton
		text: tr("common.languages.english")
		onClicked: root.selectLanguage("en")
	}

	MenuButton {
		id: czechButton
		text: tr("common.languages.czech")
		onClicked: root.selectLanguage("cz")
	}
}
