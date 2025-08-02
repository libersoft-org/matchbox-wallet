import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	title: qsTr("Select Currency")
	
	signal backRequested
	signal currencySelected(string currency)

	MenuButton {
		text: "USD"
		onClicked: {
			root.currencySelected("USD");
		}
	}

	MenuButton {
		text: "EUR"
		onClicked: {
			root.currencySelected("EUR");
		}
	}

	MenuButton {
		text: "GBP"
		onClicked: {
			root.currencySelected("GBP");
		}
	}

	MenuButton {
		text: "CHF"
		onClicked: {
			root.currencySelected("CHF");
		}
	}

	MenuButton {
		text: "CZK"
		onClicked: {
			root.currencySelected("CZK");
		}
	}

	MenuButton {
		text: qsTr("← Back")
		onClicked: {
			root.backRequested();
		}
	}
}
