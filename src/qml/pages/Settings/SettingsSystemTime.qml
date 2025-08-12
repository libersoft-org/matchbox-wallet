import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../utils/NodeUtils.js" as NodeUtils

BaseMenu {
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
					text: root.currentTime.toLocaleDateString()
					color: colors.primaryForeground
					font.pixelSize: parent.parent.height * 0.3
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

					Switch {
						id: autoSyncSwitch
						checked: Boolean(window.settingsManager && window.settingsManager.autoTimeSync)
						onToggled: {
							if (window.settingsManager)
								window.settingsManager.saveAutoTimeSync(checked);

							// Call Node.js backend to set auto time sync
							NodeUtils.msg("systemSetAutoTimeSync", {
								enabled: checked
							}, function (result) {
								console.log("Auto time sync result:", JSON.stringify(result));
								if (result.status !== "success") {
									console.error("Failed to set auto time sync:", result.message);
								}
							});
						}
					}
				}
			}
		}
	}

	MenuButton {
		text: tr("menu.settings.system.time.timezone") + ": " + (window.settingsManager ? window.settingsManager.timeZone : "UTC")
		onClicked: root.timezoneSettingsRequested()
	}

	MenuButton {
		text: tr("menu.settings.system.time.sync")
		onClicked: {
			console.log("Syncing time with internet");
			NodeUtils.msg("systemSyncTime", {}, function (result) {
				console.log("Time sync result:", JSON.stringify(result));
				if (result.status === "success") {
					console.log("Time synchronization successful");
					// Update the displayed time
					root.currentTime = new Date();
					root.timeChanged(Qt.formatTime(new Date(), "hh:mm:ss"));
				} else {
					console.error("Time sync failed:", result.message);
				}
			});
		}
	}
}
