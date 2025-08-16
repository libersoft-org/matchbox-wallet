import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "."

BaseMenu {
	id: root
	title: tr("menu.wallet.title")
	property Component balanceComponent: Component {
		WalletBalance {}
	}
	property Component sendComponent: Component {
		WalletSend {}
	}
	property Component receiveComponent: Component {
		WalletReceive {}
	}
	property Component addressBookComponent: Component {
		WalletAddressbook {}
	}
	property Component networkComponent: Component {
		WalletNetwork {}
	}

	function handleSettingsRequest() {
		window.goPage(walletSettingsPageComponent);
	}

	MenuButton {
		text: tr("menu.wallet.balance.button")
		onClicked: window.goPage(root.balanceComponent)
	}

	MenuButton {
		text: tr("menu.wallet.send.button")
		onClicked: window.goPage(root.sendComponent)
	}

	MenuButton {
		text: tr("menu.wallet.receive.button")
		onClicked: window.goPage(root.receiveComponent)
	}

	MenuButton {
		text: tr("menu.wallet.addressbook.button")
		onClicked: window.goPage(root.addressBookComponent)
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
