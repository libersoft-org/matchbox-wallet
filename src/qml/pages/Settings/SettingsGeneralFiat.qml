import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

Item {
	id: root
	property string title: qsTr("Fiat currency")
	
	signal currencySelected(string currency)
	signal backRequested
	
	property var currencies: ["USD", "EUR", "GBP", "CHF", "CZK", "PLN", "HUF"]
	
	MenuContainer {
		anchors.fill: parent
		anchors.leftMargin: root.width * 0.05
		anchors.rightMargin: root.width * 0.05
		anchors.topMargin: root.height * 0.03
		
		Repeater {
			model: root.currencies
			
			MenuButton {
				text: modelData
				onClicked: {
					root.currencySelected(modelData);
				}
			}
		}
	}
}
