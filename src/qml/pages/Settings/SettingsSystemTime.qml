import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.settings.system.time.title")
	signal timeChanged(string newTime)

	// Local alias for easier access to colors
	property var colors: window.colors

	// Get current time
	property date currentTime: new Date()

	// Current time display as Item
	Item {
		width: parent.width
		height: root.height * 0.15

		// Timer to update current time every second
		Timer {
			id: timeUpdateTimer
			interval: 1000
			running: true
			repeat: true
			onTriggered: {
				root.currentTime = new Date();
			}
		}

		Rectangle {
			anchors.fill: parent
			anchors.margins: root.height * 0.01
			color: colors.primaryBackground
			radius: height * 0.2
			border.color: colors.primaryForeground
			border.width: Math.max(1, root.height * 0.003)

			Column {
				anchors.centerIn: parent
				spacing: height * 0.1

				Text {
					text: Qt.formatTime(root.currentTime, "hh:mm:ss")
					color: colors.primaryForeground
					font.pixelSize: parent.parent.height * 0.4
					font.bold: true
					font.family: "monospace"
					anchors.horizontalCenter: parent.horizontalCenter
				}

				Text {
					text: root.currentTime.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
					color: colors.primaryForeground
					font.pixelSize: parent.parent.height * 0.2
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
			console.log("Set time clicked");
		}
	}

	MenuButton {
		text: tr("menu.settings.system.time.sync")
		onClicked: {
			// TODO: Implement NTP sync
			console.log("Syncing time with internet");
			root.timeChanged(Qt.formatTime(new Date(), "hh:mm:ss"));
		}
	}
}
