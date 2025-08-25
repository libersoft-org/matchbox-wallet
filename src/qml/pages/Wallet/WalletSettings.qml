import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("wallet.settings.title")

	function handleGeneralSettingsRequest() {
		window.goPage('Wallet/WalletSettingsGeneral.qml');
	}

	MenuButton {
		text: tr("wallet.settings.general.button")
		onClicked: root.handleGeneralSettingsRequest()
	}
}
