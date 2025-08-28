import QtQuick 6.4
import "../../components"

BaseMenu {
	id: root
	property string title: tr("wallet.settings.title")

	function handleGeneralSettingsRequest() {
		window.goPage('Wallet/WalletSettingsGeneral.qml');
	}

	MenuButton {
		text: tr("wallet.settings.general.button")
		onClicked: root.handleGeneralSettingsRequest()
	}
}
