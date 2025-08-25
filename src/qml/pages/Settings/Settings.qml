import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("settings.title")
	property string selectedLanguage: window.settingsManager ? window.settingsManager.selectedLanguage : "en"

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
		text: tr("settings.wifi.button")
		onClicked: window.goPage('Settings/SettingsWiFi.qml', "wifi-settings")
	}

	MenuButton {
		text: tr("settings.lora.button")
		enabled: false
		onClicked: console.log("LoRa settings clicked - not implemented yet")
	}

	MenuButton {
		text: tr("settings.firewall.button")
		onClicked: window.goPage('Settings/SettingsFirewall.qml', "firewall-settings")
	}

	MenuButton {
		text: tr("settings.display.button")
		onClicked: window.goPage('Settings/SettingsDisplay.qml')
	}

	MenuButton {
		text: tr("settings.sound.button")
		onClicked: window.goPage('Settings/SettingsSound.qml')
	}

	MenuButton {
		text: tr("settings.time.button")
		onClicked: window.goPage('Settings/SettingsTime.qml')
	}

	MenuButton {
		id: languageButton
		text: {
			var displayName = getLanguageDisplayName(root.selectedLanguage);
			var template = tr("settings.language.button");
			return template.replace("%1", displayName);
		}
		onClicked: window.goPage('Settings/SettingsLanguage.qml')
	}

	MenuButton {
		text: tr("settings.update.button")
		onClicked: window.goPage('Settings/SettingsUpdate.qml')
	}
}
