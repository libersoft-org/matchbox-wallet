import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	title: tr("settings.system.title")
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
		text: tr("settings.system.language", getLanguageDisplayName(root.selectedLanguage))
		onClicked: root.languageSelectionRequested();
	}

	MenuButton {
		text: tr("settings.system.wifi")
		onClicked: root.wifiSettingsRequested();
	}

	MenuButton {
		text: tr("settings.system.lora")
		enabled: false
		onClicked: console.log("LoRa settings clicked - not implemented yet");
	}
}
