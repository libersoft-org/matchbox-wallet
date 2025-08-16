import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "."

BaseMenu {
	id: root
	title: tr("menu.wallet.title")

	function handleSettingsRequest() {
		window.goPage('Wallet/WalletSettings.qml');
	}

	MenuButton {
		text: tr("menu.wallet.balance.button")
		onClicked: window.goPage('Wallet/WalletBalance.qml')
	}

	MenuButton {
		text: tr("menu.wallet.send.button")
		onClicked: window.goPage('Wallet/WalletSend.qml')
	}

	MenuButton {
		text: tr("menu.wallet.receive.button")
		onClicked: window.goPage('Wallet/WalletReceive.qml')
	}

	MenuButton {
		text: tr("menu.wallet.addressbook.button")
		onClicked: window.goPage('Wallet/WalletAddressbook.qml')
	}

	MenuButton {
		text: tr("menu.wallet.network.button")
		enabled: false
		//onClicked: goPageFunction()
	}

	MenuButton {
		text: tr("menu.wallet.address.button")
		enabled: false
		//onClicked: goPageFunction()
	}

	MenuButton {
		text: tr("menu.wallet.settings.button")
		onClicked: root.handleSettingsRequest()
	}
}
