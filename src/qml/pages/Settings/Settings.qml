import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.settings.title")
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
		text: tr("menu.settings.wifi.button")
		onClicked: window.goPage(settingsWifiPageComponent, "wifi-settings")
	}

	MenuButton {
		text: tr("menu.settings.lora.button")
		enabled: false
		onClicked: console.log("LoRa settings clicked - not implemented yet")
	}

	MenuButton {
		text: tr("menu.settings.firewall.button")
		onClicked: window.goPage(settingsFirewallPageComponent, "firewall-settings")
	}

	MenuButton {
		text: tr("menu.settings.display.button")
		onClicked: window.goPage(settingsDisplayPageComponent)
	}

	MenuButton {
		text: tr("menu.settings.sound.button")
		onClicked: window.goPage(settingsSoundPageComponent)
	}

	MenuButton {
		text: tr("menu.settings.time.button")
		onClicked: window.goPage(settingsTimePageComponent)
	}

	MenuButton {
		id: languageButton
		text: {
			var displayName = getLanguageDisplayName(root.selectedLanguage);
			var template = tr("menu.settings.language.button");
			return template.replace("%1", displayName);
		}
		onClicked: window.goPage(settingsLanguagePageComponent)
	}

	MenuButton {
		text: tr("menu.settings.update.button")
		onClicked: window.goPage(settingsUpdatePageComponent)
	}
}
