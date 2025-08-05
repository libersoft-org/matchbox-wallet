import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.settings.system.time.title")
	signal timeChanged(string newTime)
	
	// Get current time
	property date currentTime: new Date()
	
	// Current time display as Item
	Item {
		width: parent.width
		height: 50
		
		// Timer to update current time every second
		Timer {
			id: timeUpdateTimer
			interval: 1000
			running: true
			repeat: true
			onTriggered: {
				root.currentTime = new Date()
			}
		}
		
		Rectangle {
			anchors.fill: parent
			anchors.margins: 10
			color: Colors.primaryBackground
			radius: height * 0.2
			border.color: Colors.primaryForeground
			border.width: 2
			
			Column {
				anchors.centerIn: parent
				spacing: 5
				
				Text {
					text: root.currentTime.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
					color: Colors.primaryForeground
					font.pixelSize: 32
					font.bold: true
					font.family: "monospace"
					anchors.horizontalCenter: parent.horizontalCenter
				}
				
				Text {
					text: root.currentTime.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
					color: Colors.primaryForeground
					font.pixelSize: 16
					anchors.horizontalCenter: parent.horizontalCenter
				}
			}
		}
	}
	
	// Time setting buttons
	MenuButton {
		text: tr("menu.settings.system.time.set")
		onClicked: {
			// TODO: Show time setting dialog
			console.log("Set time clicked")
		}
	}
	
	MenuButton {
		text: tr("menu.settings.system.time.sync")
		onClicked: {
			// TODO: Implement NTP sync
			console.log("Syncing time with internet")
			root.timeChanged(Qt.formatTime(new Date(), "hh:mm:ss"))
		}
	}
}
