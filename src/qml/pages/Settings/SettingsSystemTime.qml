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
	property date displayTime: new Date()  // Time shown in the top display
	property bool userIsEditing: false
	property bool loadingSystemState: true  // Track if we're still loading system state

	// Component initialization
	Component.onCompleted: {
		// Load actual auto time sync status from system
		NodeUtils.msg("timeGetAutoTimeSyncStatus", {}, function (result) {
			console.log("Auto time sync status:", JSON.stringify(result));
			if (result.status === "success" && result.data) {
				autoSyncSwitch.checked = result.data.autoSync;
				// Also update settings manager if different
				if (window.settingsManager && window.settingsManager.autoTimeSync !== result.data.autoSync) {
					window.settingsManager.saveAutoTimeSync(result.data.autoSync);
				}
			}
			// Mark loading as complete
			loadingSystemState = false;
		});
	}

	// Function to mark user as editing and restart reset timer
	function markUserEditing() {
		root.userIsEditing = true;
		editResetTimer.restart();
		// Update currentTime based on user input when editing
		updateCurrentTimeFromSpinBoxes();
	}

	// Function to update currentTime based on SpinBox values
	function updateCurrentTimeFromSpinBoxes() {
		if (root.userIsEditing) {
			var newDate = new Date(yearSpinBox.currentValue, monthSpinBox.currentValue - 1 // Month is 0-indexed
			, daySpinBox.currentValue, hoursSpinBox.currentValue, minutesSpinBox.currentValue, secondsSpinBox.currentValue);
			root.currentTime = newDate;
			// Don't update displayTime - it should show actual system time always
		}
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
				// Don't change displayTime - it always shows system time
			}
		}

		// Timer to update current time every second
		Timer {
			id: timeUpdateTimer
			interval: 1000
			running: true
			repeat: true
			onTriggered: {
				// Always update displayTime with actual system time
				root.displayTime = new Date();

				if (!root.userIsEditing) {
					// Update with system time when not editing
					root.currentTime = new Date();
					hoursSpinBox.currentValue = root.currentTime.getHours();
					minutesSpinBox.currentValue = root.currentTime.getMinutes();
					secondsSpinBox.currentValue = root.currentTime.getSeconds();
					daySpinBox.currentValue = root.currentTime.getDate();
					monthSpinBox.currentValue = root.currentTime.getMonth() + 1;
					yearSpinBox.currentValue = root.currentTime.getFullYear();
				} else {
					// When editing, increment time based on current SpinBox values
					var newTime = new Date(root.currentTime.getTime() + 1000); // Add 1 second
					root.currentTime = newTime;
					// Only update seconds automatically during editing, keep other values as user set them
					secondsSpinBox.currentValue = newTime.getSeconds();
					// If seconds overflow, handle minute/hour overflow
					if (newTime.getSeconds() === 0) {
						minutesSpinBox.currentValue = newTime.getMinutes();
						if (newTime.getMinutes() === 0) {
							hoursSpinBox.currentValue = newTime.getHours();
							if (newTime.getHours() === 0) {
								daySpinBox.currentValue = newTime.getDate();
								monthSpinBox.currentValue = newTime.getMonth() + 1;
								yearSpinBox.currentValue = newTime.getFullYear();
							}
						}
					}
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
					text: Qt.formatTime(root.displayTime, "hh:mm:ss")
					color: colors.primaryForeground
					font.pixelSize: parent.parent.height * 0.4
					font.bold: true
					font.family: "monospace"
					anchors.horizontalCenter: parent.horizontalCenter
				}

				Text {
					text: root.displayTime.toLocaleDateString()
					color: colors.primaryForeground
					font.pixelSize: parent.parent.height * 0.3
					anchors.horizontalCenter: parent.horizontalCenter
				}
			}
		}
	}

	// Auto time sync toggle
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
						text: tr("menu.settings.system.time.auto") + ':'
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

	// Time setting SpinBoxes
	Item {
		width: parent.width
		height: root.height * 0.15
		visible: !loadingSystemState && !autoSyncSwitch.checked  // Hide when loading or auto sync is enabled

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

					onCurrentValueChanged: {
						if (root.userIsEditing) {
							root.updateCurrentTimeFromSpinBoxes();
						}
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

					onCurrentValueChanged: {
						if (root.userIsEditing) {
							root.updateCurrentTimeFromSpinBoxes();
						}
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

					onCurrentValueChanged: {
						if (root.userIsEditing) {
							root.updateCurrentTimeFromSpinBoxes();
						}
					}
				}
			}
		}
	}

	// Date setting SpinBoxes
	Item {
		width: parent.width
		height: root.height * 0.15
		visible: !loadingSystemState && !autoSyncSwitch.checked  // Hide when loading or auto sync is enabled

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

					onCurrentValueChanged: {
						if (root.userIsEditing) {
							root.updateCurrentTimeFromSpinBoxes();
						}
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

					onCurrentValueChanged: {
						if (root.userIsEditing) {
							root.updateCurrentTimeFromSpinBoxes();
						}
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

					onCurrentValueChanged: {
						if (root.userIsEditing) {
							root.updateCurrentTimeFromSpinBoxes();
						}
					}
				}
			}
		}
	}

	// Save button
	MenuButton {
		text: tr("menu.settings.system.time.set")
		visible: !loadingSystemState && !autoSyncSwitch.checked  // Hide when loading or auto sync is enabled
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
