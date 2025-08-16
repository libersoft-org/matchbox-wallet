import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "."

BaseMenu {
	id: root
	title: tr("menu.wallet.title")
	property var goPageFunction

	// Component definitions
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

	property var settingsPageFunction

	MenuButton {
		text: tr("menu.wallet.balance.button")
		onClicked: goPageFunction(root.balanceComponent)
	}

	MenuButton {
		text: tr("menu.wallet.send.button")
		onClicked: goPageFunction(root.sendComponent)
	}

	MenuButton {
		text: tr("menu.wallet.receive.button")
		onClicked: goPageFunction(root.receiveComponent)
	}

	MenuButton {
		text: tr("menu.wallet.addressbook.button")
		onClicked: goPageFunction(root.addressBookComponent)
	}

	MenuButton {
		text: tr("menu.wallet.network.button")
		onClicked: goPageFunction(root.networkComponent)
	}

	MenuButton {
		text: tr("menu.wallet.address.button")
		onClicked: goPageFunction(root.addressBookComponent)
	}

	MenuButton {
		text: tr("menu.wallet.settings.button")
		onClicked: root.settingsPageFunction()
	}
}
