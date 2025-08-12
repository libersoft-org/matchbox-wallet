const si = require('systeminformation');

class SystemManager {
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

	async reboot() {
		try {
			console.log('System reboot requested');
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);

			// Try multiple reboot methods in order of preference
			const rebootCommands = [
				'reboot', // Direct reboot (works if running as root)
				'sudo reboot', // With sudo
				'systemctl reboot', // systemd
				'sudo systemctl reboot',
				'/sbin/reboot', // Direct path
				'sudo /sbin/reboot',
			];

			let lastError = null;
			for (const cmd of rebootCommands) {
				try {
					console.log(`Trying reboot command: ${cmd}`);
					await execAsync(cmd);
					return {
						status: 'success',
						message: `System reboot initiated with: ${cmd}`,
					};
				} catch (error) {
					console.log(`Reboot command failed: ${cmd} - ${error.message}`);
					lastError = error;
					continue;
				}
			}

			throw lastError || new Error('All reboot methods failed');
		} catch (error) {
			console.error('Reboot failed:', error);
			return {
				status: 'error',
				message: `Failed to reboot system: ${error.message}`,
			};
		}
	}

	async shutdown() {
		try {
			console.log('System shutdown requested');
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);

			// Try multiple shutdown methods in order of preference
			const shutdownCommands = [
				'poweroff', // Direct poweroff (works if running as root)
				'shutdown -h now', // Traditional shutdown
				'sudo poweroff', // With sudo
				'sudo shutdown -h now', // With sudo
				'systemctl poweroff', // systemd
				'sudo systemctl poweroff',
				'/sbin/poweroff', // Direct path
				'sudo /sbin/poweroff',
				'halt', // Halt system
				'sudo halt',
			];

			let lastError = null;
			for (const cmd of shutdownCommands) {
				try {
					console.log(`Trying shutdown command: ${cmd}`);
					await execAsync(cmd);
					return {
						status: 'success',
						message: `System shutdown initiated with: ${cmd}`,
					};
				} catch (error) {
					console.log(`Shutdown command failed: ${cmd} - ${error.message}`);
					lastError = error;
					continue;
				}
			}

			throw lastError || new Error('All shutdown methods failed');
		} catch (error) {
			console.error('Shutdown failed:', error);
			return {
				status: 'error',
				message: `Failed to shutdown system: ${error.message}`,
			};
		}
	}

	async listTimeZones() {
		try {
			console.log('Listing available time zones from system');
			const systemTimezones = await this.loadSystemTimeZones();
			if (systemTimezones && systemTimezones.length > 0) {
				console.log(`Loaded ${systemTimezones.length} time zones from system`);
				return {
					status: 'success',
					data: systemTimezones,
				};
			}
			console.log('System timezone loading failed, no timezones available');
			return {
				status: 'error',
				message: 'Unable to load system timezones',
				data: [],
			};
		} catch (error) {
			console.error('Error listing time zones:', error);
			return {
				status: 'error',
				message: error.message,
				data: [],
			};
		}
	}

	async loadSystemTimeZones() {
		try {
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);
			console.log('Loading timezones using timedatectl only');
			const { stdout } = await execAsync('timedatectl list-timezones 2>/dev/null');
			if (stdout && stdout.trim()) {
				const timezones = stdout
					.trim()
					.split('\n')
					.filter((tz) => tz.trim().length > 0);
				if (timezones.length > 0) {
					console.log(`Found ${timezones.length} timezones via timedatectl`);
					return timezones.sort();
				}
			}
			throw new Error('timedatectl returned no timezones');
		} catch (error) {
			console.error('Error loading timezones via timedatectl:', error.message);
			return null;
		}
	}
}

module.exports = SystemManager;
