import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../components"

BaseMenu {
	id: root
	title: tr("wallet.title")
	property var goPageFunction

	MenuButton {
		text: tr("wallet.balance")
		enabled: false
	}
	
	MenuButton {
		text: tr("wallet.send")
		enabled: false
	}

	MenuButton {
		text: tr("wallet.receive")
		enabled: false
	}

	MenuButton {
		text: tr("wallet.addressbook")
		enabled: false
	}
}
