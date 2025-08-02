import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../components"

BaseMenu {
	id: root
	title: tr("power.title")
	property bool showPowerButton: false
	
	property SystemManager systemManager: SystemManager { }
	
	MenuButton {
		text: tr("power.quit")
		onClicked: Qt.quit()
	}

	MenuButton {
		text: tr("power.reboot")
		onClicked: systemManager.rebootSystem()
	}

	MenuButton {
		text: tr("power.shutdown")
		onClicked: systemManager.shutdownSystem()
	}
}
