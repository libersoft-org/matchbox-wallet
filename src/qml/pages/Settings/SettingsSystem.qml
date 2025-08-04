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
			case "en": return "English"
			case "cz": return "Czech"
			default: return langCode
		}
	}

	MenuButton {
		id: languageButton
		text: tr("menu.settings.system.language.button", getLanguageDisplayName(root.selectedLanguage))
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
