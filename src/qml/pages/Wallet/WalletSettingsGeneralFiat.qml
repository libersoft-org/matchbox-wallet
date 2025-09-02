import QtQuick 6.8
import "../../components"

BaseMenu {
	id: root
	property string title: tr("wallet.settings.general.fiat.title")
	property var currencies: ["USD", "EUR", "GBP", "CHF", "CZK", "PLN", "HUF"]

	function selectCurrency(currency) {
		window.settingsManager.saveCurrency(currency);
		window.goBack();
	}

	Repeater {
		model: root.currencies

		MenuButton {
			text: modelData
			onClicked: root.selectCurrency(modelData)
		}
	}
}
