import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.settings.system.title")
	signal wifiSettingsRequested
	signal languageSelectionRequested
	
	property string selectedLanguage: "en"
	
	function getLanguageDisplayName(langCode) {
		switch(langCode) {
			case "en": return tr("common.languages.english")
			case "cz": return tr("common.languages.czech")
			default: return langCode
		}
	}

	MenuButton {
		id: languageButton
		text: {
			var displayName = getLanguageDisplayName(root.selectedLanguage)
			var template = tr("menu.settings.system.language.button")
			return template.replace("%1", displayName)
		}
		onClicked: root.languageSelectionRequested();
	}

	MenuButton {
		text: tr("menu.settings.system.wifi.button")
		onClicked: root.wifiSettingsRequested();
	}

	MenuButton {
		text: tr("menu.settings.system.lora.button")
		enabled: false
		onClicked: console.log("LoRa settings clicked - not implemented yet");
	}
}
