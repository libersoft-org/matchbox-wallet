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

	async changeTimeZone(params) {
		try {
			console.log('Changing system timezone to:', params.timezone);
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);

			if (!params.timezone) {
				throw new Error('Timezone parameter is required');
			}

			// Try multiple timezone change methods in order of preference
			const timezoneCommands = [
				`timedatectl set-timezone ${params.timezone}`, // systemd timedatectl (preferred)
				`sudo timedatectl set-timezone ${params.timezone}`, // with sudo
				`ln -sf /usr/share/zoneinfo/${params.timezone} /etc/localtime`, // direct symlink
				`sudo ln -sf /usr/share/zoneinfo/${params.timezone} /etc/localtime`, // with sudo
			];

			let lastError = null;
			for (const cmd of timezoneCommands) {
				try {
					console.log(`Trying timezone command: ${cmd}`);
					await execAsync(cmd);

					// Verify the change worked
					const { stdout } = await execAsync('timedatectl show --property=Timezone --value');
					const currentTimezone = stdout.trim();

					if (currentTimezone === params.timezone) {
						console.log(`Successfully changed timezone to: ${currentTimezone}`);
						return {
							status: 'success',
							message: `Timezone changed to ${params.timezone}`,
							data: {
								timezone: currentTimezone,
							},
						};
					} else {
						console.log(`Timezone change verification failed. Expected: ${params.timezone}, Got: ${currentTimezone}`);
					}
				} catch (error) {
					console.log(`Timezone command failed: ${cmd} - ${error.message}`);
					lastError = error;
					continue;
				}
			}

			throw lastError || new Error('All timezone change methods failed');
		} catch (error) {
			console.error('Timezone change failed:', error);
			return {
				status: 'error',
				message: `Failed to change timezone: ${error.message}`,
			};
		}
	}

	async syncSystemTime() {
		try {
			console.log('Syncing system time with internet');
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);

			// Try multiple time sync methods in order of preference
			const timeSyncCommands = [
				'timedatectl set-ntp true', // Enable NTP via systemd
				'sudo timedatectl set-ntp true', // With sudo
			];

			let lastError = null;
			let syncResult = null;

			for (const cmd of timeSyncCommands) {
				try {
					console.log(`Trying time sync command: ${cmd}`);
					const result = await execAsync(cmd);
					// If command succeeded, verify time sync status
					try {
						const { stdout } = await execAsync('timedatectl status');
						console.log('Time sync status:', stdout);
						syncResult = {
							status: 'success',
							message: `Time synchronization initiated with: ${cmd}`,
							data: {
								command: cmd,
								output: result.stdout,
								timeStatus: stdout,
							},
						};
						break;
					} catch (statusError) {
						console.log('Could not verify time status:', statusError.message);
						syncResult = {
							status: 'success',
							message: `Time synchronization initiated with: ${cmd}`,
							data: {
								command: cmd,
								output: result.stdout,
							},
						};
						break;
					}
				} catch (error) {
					console.log(`Time sync command failed: ${cmd} - ${error.message}`);
					lastError = error;
					continue;
				}
			}

			if (syncResult) {
				console.log('Time synchronization completed successfully');
				return syncResult;
			}

			throw lastError || new Error('All time sync methods failed');
		} catch (error) {
			console.error('Time sync failed:', error);
			return {
				status: 'error',
				message: `Failed to sync system time: ${error.message}`,
			};
		}
	}

	async setAutoTimeSync(enabled) {
		try {
			console.log('Setting auto time sync to:', enabled);
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);
			const ntpCommand = enabled ? 'timedatectl set-ntp true' : 'timedatectl set-ntp false';
			const sudoNtpCommand = enabled ? 'sudo timedatectl set-ntp true' : 'sudo timedatectl set-ntp false';
			try {
				console.log(`Trying command: ${ntpCommand}`);
				await execAsync(ntpCommand);
			} catch (error) {
				console.log(`Command failed, trying with sudo: ${sudoNtpCommand}`);
				await execAsync(sudoNtpCommand);
			}
			// Verify the change
			const { stdout } = await execAsync('timedatectl status');
			const ntpEnabled = stdout.includes('NTP enabled: yes') || stdout.includes('Network time on: yes');
			return {
				status: 'success',
				message: `Auto time sync ${enabled ? 'enabled' : 'disabled'}`,
				data: {
					autoSync: ntpEnabled,
					timeStatus: stdout,
				},
			};
		} catch (error) {
			console.error('Auto time sync setting failed:', error);
			return {
				status: 'error',
				message: `Failed to set auto time sync: ${error.message}`,
			};
		}
	}
}

module.exports = SystemManager;
