import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import "../../components"
import "../../utils/NodeUtils.js" as NodeUtils

BaseMenu {
	id: root
	property string title: tr("settings.time.title")
	signal timezoneChanged
	property date displayTime: new Date()  // Time shown in the top display
	property date spinBoxTime: new Date()  // Independent time for spinboxes
	property bool updatingFromTimer: false  // Flag to prevent onCurrentValueChanged during timer updates
	property bool loadingSystemState: true  // Track if we're still loading system state
	property string currentTimezone: "UTC"  // Current system timezone

	function handleTimeChange(timeString) {
		console.log("Time changed to:", timeString);
		// TODO: Implement actual system time setting
		window.goBack();
	}

	function handleTimezoneSettingsRequested() {
		window.goPage('Settings/SettingsTimeZones.qml');
	}

	// Refresh timezone when page becomes visible (when returning from timezone settings)
	onVisibleChanged: {
		if (visible) {
			console.log("SettingsTime became visible, refreshing timezone");
			refreshTimezone();
		}
	}

	function updateSpinBoxes() {
		root.updatingFromTimer = true;
		hoursSpinBox.currentValue = root.spinBoxTime.getHours();
		minutesSpinBox.currentValue = root.spinBoxTime.getMinutes();
		secondsSpinBox.currentValue = root.spinBoxTime.getSeconds();
		daySpinBox.currentValue = root.spinBoxTime.getDate();
		monthSpinBox.currentValue = root.spinBoxTime.getMonth() + 1;
		yearSpinBox.currentValue = root.spinBoxTime.getFullYear();
		root.updatingFromTimer = false;
	}

	function updateSpinBoxTimeFromUser() {
		if (!root.updatingFromTimer)
			root.spinBoxTime = new Date(yearSpinBox.currentValue, monthSpinBox.currentValue - 1, daySpinBox.currentValue, hoursSpinBox.currentValue, minutesSpinBox.currentValue, secondsSpinBox.currentValue);
	}

	function refreshTimezone() {
		// Reload timezone from system
		NodeUtils.msg("timeGetCurrentTimezone", {}, function (result) {
			console.log("Refreshed timezone result:", JSON.stringify(result));
			if (result.status === "success" && result.data && result.data.timezone) {
				root.currentTimezone = result.data.timezone;
				console.log("Refreshed timezone from system:", root.currentTimezone);
			}
		});
	}

	// Component initialization
	Component.onCompleted: {
		// Initialize with current system time
		var now = new Date();
		root.displayTime = now;
		root.spinBoxTime = now;
		updateSpinBoxes();

		// Load current timezone from system
		NodeUtils.msg("timeGetCurrentTimezone", {}, function (result) {
			console.log("Current timezone result:", JSON.stringify(result));
			if (result.status === "success" && result.data && result.data.timezone) {
				root.currentTimezone = result.data.timezone;
				console.log("Loaded current timezone from system:", root.currentTimezone);
			} else {
				console.log("Failed to get timezone, using UTC");
				root.currentTimezone = "UTC";
			}
		});

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

	// Current time display as Item
	Item {
		width: parent.width
		height: root.height * 0.15

		// Timer to update both times every second
		Timer {
			id: timeUpdateTimer
			interval: 1000
			running: true
			repeat: true
			onTriggered: {
				// Always update displayTime with actual system time
				root.displayTime = new Date();

				// Always increment spinBoxTime by 1 second
				root.spinBoxTime = new Date(root.spinBoxTime.getTime() + 1000);

				// Update SpinBox values from spinBoxTime (with flag handling)
				updateSpinBoxes();
			}
		}

		Rectangle {
			anchors.fill: parent
			anchors.margins: window.height * 0.01
			color: colors.primaryBackground
			radius: window.width * 0.04
			border.color: colors.primaryForeground
			border.width: window.width * 0.004

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
		height: window.width * 0.16

		Rectangle {
			anchors.fill: parent
			anchors.margins: window.height * 0.01
			color: colors.primaryBackground
			radius: window.width * 0.04
			border.color: colors.primaryForeground
			border.width: window.width * 0.004

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: parent.height * 0.15
				spacing: parent.height * 0.1

				RowLayout {
					Layout.fillWidth: true
					spacing: parent.height * 0.2

					Text {
						text: tr("settings.time.auto") + ':'
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
					leadingZeros: true
					minimumDigits: 2
					width: parent.parent.width * 0.25
					height: parent.parent.height * 0.6
					onCurrentValueChanged: updateSpinBoxTimeFromUser()
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
					leadingZeros: true
					minimumDigits: 2
					width: parent.parent.width * 0.25
					height: parent.parent.height * 0.6
					onCurrentValueChanged: updateSpinBoxTimeFromUser()
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
					leadingZeros: true
					minimumDigits: 2
					width: parent.parent.width * 0.25
					height: parent.parent.height * 0.6
					onCurrentValueChanged: updateSpinBoxTimeFromUser()
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
					leadingZeros: true
					minimumDigits: 2
					width: parent.parent.width * 0.25
					height: parent.parent.height * 0.6
					onCurrentValueChanged: updateSpinBoxTimeFromUser()
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
					leadingZeros: true
					minimumDigits: 2
					width: parent.parent.width * 0.25
					height: parent.parent.height * 0.6
					onCurrentValueChanged: updateSpinBoxTimeFromUser()
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
					maxValue: 2999
					leadingZeros: false
					minimumDigits: 4
					width: parent.parent.width * 0.25
					height: parent.parent.height * 0.6
					onCurrentValueChanged: updateSpinBoxTimeFromUser()
				}
			}
		}
	}

	// Save button
	MenuButton {
		text: tr("settings.time.set")
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
					root.handleTimeChange(Qt.formatTime(new Date(), "hh:mm:ss"));
					// Keep SpinBox time as it is - it's already set to what user wanted
					// No need to change spinBoxTime as it should continue from user-set values
				} else {
					console.error("Failed to set date/time:", result.message);
				}
			});
		}
	}

	MenuButton {
		text: tr("settings.time.timezone") + ": " + root.currentTimezone
		onClicked: root.handleTimezoneSettingsRequested()
	}
}
