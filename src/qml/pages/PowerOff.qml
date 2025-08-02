import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

BaseMenu {
	id: root
	title: qsTr("Power options")
	signal backRequested
	
	function exitApplication() {
		Qt.quit();
	}
	
	function rebootSystem() {
		QProcess.startDetached("reboot");
	}
	
	function shutdownSystem() {
		QProcess.startDetached("shutdown", ["-h", "now"]);
	}

	MenuButton {
		text: qsTr("Exit application")
		onClicked: root.exitApplication()
	}

	MenuButton {
		text: qsTr("Reboot")
		onClicked: root.rebootSystem()
	}

	MenuButton {
		text: qsTr("Power off")
		onClicked: root.shutdownSystem()
	}

	MenuButton {
		text: qsTr("Back to main menu")
		onClicked: root.backRequested()
	}
}
