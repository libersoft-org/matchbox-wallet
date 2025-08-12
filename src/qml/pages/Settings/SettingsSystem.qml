import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.settings.system.title")
	signal wifiSettingsRequested
	signal languageSelectionRequested
	signal timeSettingsRequested
	signal soundSettingsRequested
	signal displaySettingsRequested
	signal updateSettingsRequested

	property string selectedLanguage: "en"

	function getLanguageDisplayName(langCode) {
		switch (langCode) {
		case "en":
			return tr("common.languages.english");
		case "cz":
			return tr("common.languages.czech");
		default:
			return langCode;
		}
	}

	MenuButton {
		text: tr("menu.settings.system.wifi.button")
		onClicked: root.wifiSettingsRequested()
	}

	MenuButton {
		text: tr("menu.settings.system.lora.button")
		enabled: false
		onClicked: console.log("LoRa settings clicked - not implemented yet")
	}

	MenuButton {
		text: tr("menu.settings.system.display.button")
		onClicked: root.displaySettingsRequested()
	}

	MenuButton {
		text: tr("menu.settings.system.sound.button")
		onClicked: root.soundSettingsRequested()
	}

	MenuButton {
		text: tr("menu.settings.system.time.button")
		onClicked: root.timeSettingsRequested()
	}

	MenuButton {
		id: languageButton
		text: {
			var displayName = getLanguageDisplayName(root.selectedLanguage);
			var template = tr("menu.settings.system.language.button");
			return template.replace("%1", displayName);
		}
		onClicked: root.languageSelectionRequested()
	}

	MenuButton {
		text: tr("menu.settings.system.update.button")
		onClicked: root.updateSettingsRequested()
	}
}
