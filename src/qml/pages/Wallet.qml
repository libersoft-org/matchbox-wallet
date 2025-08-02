import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

BaseMenu {
	id: root
	title: qsTr("Wallet")
	property var goPageFunction

	MenuButton {
		text: qsTr("Balance")
		enabled: false
	}
	
	MenuButton {
		text: qsTr("Send")
		enabled: false
	}

	MenuButton {
		text: qsTr("Receive")
		enabled: false
	}

	MenuButton {
		text: qsTr("Addressbook")
		enabled: false
	}
}
