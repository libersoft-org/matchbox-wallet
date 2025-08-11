import QtQuick 2.15

Item {
	id: batteryManager

	// Properties
	property int batteryLevel: 0
	property bool hasBattery: false
	property bool charging: false

	// Internal timer for periodic updates
	property Timer updateTimer: Timer {
		interval: 10000 // 10 seconds
		running: true
		repeat: true
		onTriggered: batteryManager.updateBatteryStatus()
	}

	// Functions
	function updateBatteryStatus() {
		if (typeof NodeJS !== 'undefined') {
			NodeJS.msg("systemCheckBatteryStatus", {}, function (result) {
				if (result && result.status === "success" && result.data) {
					var data = result.data;
					if (data.batteryLevel !== undefined) {
						batteryLevel = data.batteryLevel;
					}
					if (data.charging !== undefined) {
						charging = data.charging;
					}
					if (data.hasBattery !== undefined) {
						hasBattery = data.hasBattery;
					}
				}
			});
		}
	}

	function getBatteryInfo() {
		if (typeof NodeJS !== 'undefined') {
			NodeJS.msg("systemGetBatteryInfo", {}, function (result) {
				console.log("Battery info:", JSON.stringify(result));
				if (result && result.status === "success" && result.data) {
					var data = result.data;
					if (data.batteryLevel !== undefined) {
						batteryLevel = data.batteryLevel;
					}
					if (data.charging !== undefined) {
						charging = data.charging;
					}
					if (data.hasBattery !== undefined) {
						hasBattery = data.hasBattery;
					}
				}
			});
		}
	}

	// Initialize battery info when component is created
	Component.onCompleted: {
		getBatteryInfo();
	}
}
