import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components" as Components

Components.BaseMenu {
	id: root
	title: tr("menu.settings.system.time.title")
	signal timeChanged(string newTime)
	signal timezoneSettingsRequested
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

	// Auto time sync toggle + timezone open button
	Item {
		width: parent.width
		height: root.height * 0.12

		Rectangle {
			anchors.fill: parent
			anchors.margins: root.height * 0.01
			color: colors.primaryBackground
			radius: height * 0.2
			border.color: colors.primaryForeground
			border.width: Math.max(1, root.height * 0.003)

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: parent.height * 0.15
				spacing: parent.height * 0.1

				RowLayout {
					Layout.fillWidth: true
					spacing: parent.height * 0.2

					Text {
						text: tr("menu.settings.system.time.auto")
						color: colors.primaryForeground
						font.pixelSize: parent.height * 0.35
						Layout.alignment: Qt.AlignVCenter
						Layout.fillWidth: true
					}

					Components.Switch {
						id: autoSyncSwitch
						checked: Boolean(window.settingsManager && window.settingsManager.autoTimeSync)
						onToggled: {
							if (window.settingsManager)
								window.settingsManager.saveAutoTimeSync(checked);
							if (SystemManager && SystemManager.setAutoTimeSync)
								SystemManager.setAutoTimeSync(checked);
						}
					}
				}

				Components.MenuButton {
					text: tr("menu.settings.system.time.timezone") + ": " + (window.settingsManager ? window.settingsManager.timeZone : "UTC")
					onClicked: root.timezoneSettingsRequested()
				}
			}
		}
	}

	// NTP server field removed from here as requested

	Components.MenuButton {
		text: tr("menu.settings.system.time.sync")
		onClicked: {
			console.log("Syncing time with internet");
			if (SystemManager && SystemManager.syncSystemTime) {
				SystemManager.syncSystemTime();
			}
			root.timeChanged(Qt.formatTime(new Date(), "hh:mm:ss"));
		}
	}
}
