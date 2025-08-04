import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.settings.general.title")

	signal currencySelectionRequested
	
	property string selectedCurrency: "USD"
	
	MenuButton {
		text: {
			var template = tr("menu.settings.general.fiat.button")
			return template.replace("%1", root.selectedCurrency)
		}
		onClicked: {
			root.currencySelectionRequested();
		}
	}
}
