import QtQuick 6.4
import "../../components"

BaseMenu {
	id: root
	property string title: tr("wallet.title")

	function handleSettingsRequest() {
		window.goPage('Wallet/WalletSettings.qml');
	}

	MenuButton {
		text: tr("wallet.balance.button")
		onClicked: window.goPage('Wallet/WalletBalance.qml')
	}

	MenuButton {
		text: tr("wallet.send.button")
		onClicked: window.goPage('Wallet/WalletSend.qml')
	}

	MenuButton {
		text: tr("wallet.receive.button")
		onClicked: window.goPage('Wallet/WalletReceive.qml')
	}

	MenuButton {
		text: tr("wallet.addressbook.button")
		onClicked: window.goPage('Wallet/WalletAddressbook.qml')
	}

	MenuButton {
		text: tr("wallet.network.button")
		enabled: false
		//onClicked: goPageFunction()
	}

	MenuButton {
		text: tr("wallet.address.button")
		enabled: false
		//onClicked: goPageFunction()
	}

	MenuButton {
		text: tr("wallet.settings.button")
		onClicked: root.handleSettingsRequest()
	}
}
