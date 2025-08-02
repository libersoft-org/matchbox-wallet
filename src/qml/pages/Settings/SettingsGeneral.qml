import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	title: qsTr("General Settings")
	
	signal currencySelectionRequested
	
	property string selectedCurrency: "USD"
	
	MenuButton {
		text: qsTr("Fiat Currency: %1").arg(root.selectedCurrency)
		onClicked: {
			root.currencySelectionRequested();
		}
	}
}
