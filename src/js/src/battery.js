const si = require('systeminformation');

class BatteryManager {
	async getBatteryInfo() {
		try {
			const battery = await si.battery();
			return {
				status: 'success',
				data: {
					hasBattery: battery.hasBattery,
					batteryLevel: battery.percent || 0,
					charging: battery.isCharging,
					acConnected: battery.acConnected,
					type: battery.type,
					model: battery.model,
					vendor: battery.vendor,
					maxCapacity: battery.maxCapacity,
					currentCapacity: battery.currentCapacity,
					capacityUnit: battery.capacityUnit,
					voltage: battery.voltage,
					designedCapacity: battery.designedCapacity,
					timeRemaining: battery.timeRemaining,
					additionalBatteries: battery.additionalBatteries || [],
				},
			};
		} catch (error) {
			return {
				status: 'error',
				message: error.message,
				data: {
					hasBattery: false,
					batteryLevel: 0,
					charging: false,
				},
			};
		}
	}

	async checkBatteryStatus() {
		try {
			const battery = await si.battery();
			return {
				status: 'success',
				data: {
					batteryLevel: battery.percent || 0,
					charging: battery.isCharging,
					hasBattery: battery.hasBattery,
				},
			};
		} catch (error) {
			return {
				status: 'error',
				message: error.message,
				data: {
					batteryLevel: 0,
					charging: false,
					hasBattery: false,
				},
			};
		}
	}
}

module.exports = BatteryManager;
