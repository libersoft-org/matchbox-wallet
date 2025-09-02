import QtQuick 6.4
import "../../components"

BaseMenu {
	id: root
	property string title: "bli"

	MenuButton {
		text: tr("wallet.balance.button")
		onClicked: window.goPage('Wallet/WalletBalance.qml')
	}
}
