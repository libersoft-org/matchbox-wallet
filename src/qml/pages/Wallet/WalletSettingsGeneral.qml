import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.wallet.settings.general.title")

	property string selectedCurrency: window.settingsManager ? window.settingsManager.selectedCurrency : "USD"

	function handleCurrencySelectionRequest() {
		window.goPage(walletSettingsGeneralFiatPageComponent);
	}

	MenuButton {
		text: {
			var template = tr("menu.wallet.settings.general.fiat.button");
			return template.replace("%1", root.selectedCurrency);
		}
		onClicked: {
			root.handleCurrencySelectionRequest();
		}
	}
}
