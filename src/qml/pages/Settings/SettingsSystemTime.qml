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
	property bool userIsEditing: false

	// Function to mark user as editing and restart reset timer
	function markUserEditing() {
		root.userIsEditing = true;
		editResetTimer.restart();
	}

	// Current time display as Item
	Item {
		width: parent.width
		height: root.height * 0.15

		// Timer to reset editing state after period of inactivity
		Timer {
			id: editResetTimer
			interval: 5000 // 5 seconds
			running: false
			repeat: false
			onTriggered: {
				root.userIsEditing = false;
			}
		}

		// Timer to update current time every second
		Timer {
			id: timeUpdateTimer
			interval: 1000
			running: true
			repeat: true
			onTriggered: {
				root.currentTime = new Date();
				// Update SpinBoxes only if user is not editing
				if (!root.userIsEditing) {
					hoursSpinBox.currentValue = root.currentTime.getHours();
					minutesSpinBox.currentValue = root.currentTime.getMinutes();
					secondsSpinBox.currentValue = root.currentTime.getSeconds();
					daySpinBox.currentValue = root.currentTime.getDate();
					monthSpinBox.currentValue = root.currentTime.getMonth() + 1;
					yearSpinBox.currentValue = root.currentTime.getFullYear();
				}
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

	// Time setting SpinBoxes
	Item {
		width: parent.width
		height: root.height * 0.15

		Column {
			anchors.fill: parent
			anchors.margins: parent.height * 0.1
			spacing: parent.height * 0.05

			Row {
				anchors.horizontalCenter: parent.horizontalCenter
				spacing: parent.width * 0.02

				Stepper {
					id: hoursSpinBox
					minValue: 0
					maxValue: 23
					currentValue: root.currentTime.getHours()
					leadingZeros: true
					minimumDigits: 2
					width: parent.parent.width * 0.25
					height: parent.parent.height * 0.6

					onUserInteraction: {
						root.markUserEditing();
					}
				}

				Text {
					text: ":"
					color: colors.primaryForeground
					font.pixelSize: parent.parent.height * 0.4
					anchors.verticalCenter: parent.verticalCenter
				}

				Stepper {
					id: minutesSpinBox
					minValue: 0
					maxValue: 59
					currentValue: root.currentTime.getMinutes()
					leadingZeros: true
					minimumDigits: 2
					width: parent.parent.width * 0.25
					height: parent.parent.height * 0.6

					onUserInteraction: {
						root.markUserEditing();
					}
				}

				Text {
					text: ":"
					color: colors.primaryForeground
					font.pixelSize: parent.parent.height * 0.4
					anchors.verticalCenter: parent.verticalCenter
				}

				Stepper {
					id: secondsSpinBox
					minValue: 0
					maxValue: 59
					currentValue: root.currentTime.getSeconds()
					leadingZeros: true
					minimumDigits: 2
					width: parent.parent.width * 0.25
					height: parent.parent.height * 0.6

					onUserInteraction: {
						root.markUserEditing();
					}
				}
			}
		}
	}

	// Date setting SpinBoxes
	Item {
		width: parent.width
		height: root.height * 0.15

		Column {
			anchors.fill: parent
			anchors.margins: parent.height * 0.1
			spacing: parent.height * 0.05

			Row {
				anchors.horizontalCenter: parent.horizontalCenter
				spacing: parent.width * 0.02

				Stepper {
					id: daySpinBox
					minValue: 1
					maxValue: 31
					currentValue: root.currentTime.getDate()
					leadingZeros: true
					minimumDigits: 2
					width: parent.parent.width * 0.25
					height: parent.parent.height * 0.6

					onUserInteraction: {
						root.markUserEditing();
					}
				}

				Text {
					text: "."
					color: colors.primaryForeground
					font.pixelSize: parent.parent.height * 0.4
					anchors.verticalCenter: parent.verticalCenter
				}

				Stepper {
					id: monthSpinBox
					minValue: 1
					maxValue: 12
					currentValue: root.currentTime.getMonth() + 1
					leadingZeros: true
					minimumDigits: 2
					width: parent.parent.width * 0.25
					height: parent.parent.height * 0.6

					onUserInteraction: {
						root.markUserEditing();
					}
				}

				Text {
					text: "."
					color: colors.primaryForeground
					font.pixelSize: parent.parent.height * 0.4
					anchors.verticalCenter: parent.verticalCenter
				}

				Stepper {
					id: yearSpinBox
					minValue: 1970
					maxValue: 2100
					currentValue: root.currentTime.getFullYear()
					leadingZeros: false
					minimumDigits: 4
					width: parent.parent.width * 0.25
					height: parent.parent.height * 0.6

					onUserInteraction: {
						root.markUserEditing();
					}
				}
			}
		}
	}

	// Save button
	MenuButton {
		text: tr("menu.settings.system.time.set")
		onClicked: {
			console.log("Saving date and time...");
			NodeUtils.msg("timeSetSystemDateTime", {
				hours: hoursSpinBox.currentValue,
				minutes: minutesSpinBox.currentValue,
				seconds: secondsSpinBox.currentValue,
				day: daySpinBox.currentValue,
				month: monthSpinBox.currentValue,
				year: yearSpinBox.currentValue
			}, function (result) {
				console.log("Set date/time result:", JSON.stringify(result));
				if (result.status === "success") {
					console.log("Date and time set successfully");
					// Update the displayed time
					root.currentTime = new Date();
					root.timeChanged(Qt.formatTime(new Date(), "hh:mm:ss"));
					// Reset editing state after successful save
					root.userIsEditing = false;
					editResetTimer.stop();
				} else {
					console.error("Failed to set date/time:", result.message);
				}
			});
		}
	}

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
							NodeUtils.msg("timeSetAutoTimeSync", {
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
			NodeUtils.msg("timeSyncTime", {}, function (result) {
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
