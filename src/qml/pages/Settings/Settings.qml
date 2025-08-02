import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	title: tr("settings.title")
	
	signal systemSettingsRequested
	signal generalSettingsRequested

	MenuButton {
		text: tr("settings.general")
		onClicked: root.generalSettingsRequested();
	}

	MenuButton {
		text: tr("settings.wallets")
		onClicked: console.log("Wallets settings clicked");
		enabled:	false
	}

	MenuButton {
		text: tr("settings.networks")
		onClicked: console.log("Networks settings clicked");
		enabled: false
	}

	MenuButton {
		text: tr("settings.system")
		onClicked: root.systemSettingsRequested();
	}
}
