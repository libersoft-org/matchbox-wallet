import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.settings.title")
	signal settingsWifiRequested
	signal settingsLanguageRequested
	signal settingsTimeRequested
	signal settingsSoundRequested
	signal settingsDisplayRequested
	signal settingsUpdateRequested
	signal settingsFirewallRequested
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
		text: tr("menu.settings.wifi.button")
		onClicked: root.settingsWifiRequested()
	}

	MenuButton {
		text: tr("menu.settings.lora.button")
		enabled: false
		onClicked: console.log("LoRa settings clicked - not implemented yet")
	}

	MenuButton {
		text: tr("menu.settings.firewall.button")
		onClicked: root.settingsFirewallRequested()
	}

	MenuButton {
		text: tr("menu.settings.display.button")
		onClicked: root.settingsDisplayRequested()
	}

	MenuButton {
		text: tr("menu.settings.sound.button")
		onClicked: root.settingsSoundRequested()
	}

	MenuButton {
		text: tr("menu.settings.time.button")
		onClicked: root.settingsTimeRequested()
	}

	MenuButton {
		id: languageButton
		text: {
			var displayName = getLanguageDisplayName(root.selectedLanguage);
			var template = tr("menu.settings.language.button");
			return template.replace("%1", displayName);
		}
		onClicked: root.settingsLanguageRequested()
	}

	MenuButton {
		text: tr("menu.settings.update.button")
		onClicked: root.settingsUpdateRequested()
	}
}
