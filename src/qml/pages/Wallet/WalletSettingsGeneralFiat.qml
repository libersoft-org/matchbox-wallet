import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.wallet.settings.general.fiat.title")
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
