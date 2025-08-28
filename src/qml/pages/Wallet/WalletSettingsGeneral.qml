import QtQuick 6.4
import "../../components"

BaseMenu {
	id: root
	property string title: tr("wallet.settings.general.title")
	property string selectedCurrency: window.settingsManager ? window.settingsManager.selectedCurrency : "USD"

	function handleCurrencySelectionRequest() {
		window.goPage('Wallet/WalletSettingsGeneralFiat.qml');
	}

	MenuButton {
		text: {
			var template = tr("wallet.settings.general.fiat.button");
			return template.replace("%1", root.selectedCurrency);
		}
		onClicked: {
			root.handleCurrencySelectionRequest();
		}
	}
}
