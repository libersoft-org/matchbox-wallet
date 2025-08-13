class TimeManager {
	async listTimeZones() {
		try {
			console.log('Listing available time zones from system');
			const systemTimezones = await this.loadSystemTimeZones();
			if (systemTimezones && systemTimezones.length > 0) {
				console.log('Loaded ' + systemTimezones.length + ' time zones from system');
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
				const allTimezones = stdout
					.trim()
					.split('\n')
					.filter((tz) => tz.trim().length > 0);
				if (allTimezones.length > 0) {
					console.log('Found ' + allTimezones.length + ' timezones via timedatectl');

					// Use more efficient filtering - get list of actual timezone files first
					try {
						const { stdout: filesOutput } = await execAsync('find /usr/share/zoneinfo -type f | grep -v "/right/" | grep -v "/posix/" | sed "s|/usr/share/zoneinfo/||" | sort');
						const existingFiles = new Set(
							filesOutput
								.trim()
								.split('\n')
								.filter((f) => f.length > 0)
						);

						// Filter timezones to only include those with actual files
						const validTimezones = allTimezones.filter((tz) => existingFiles.has(tz));

						console.log('Filtered to ' + validTimezones.length + ' valid timezones with files');
						return validTimezones.sort();
					} catch (e) {
						console.log('File-based filtering failed, using all timezones:', e.message);
						return allTimezones.sort();
					}
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
				'timedatectl set-timezone ' + params.timezone, // systemd timedatectl (preferred)
				'sudo timedatectl set-timezone ' + params.timezone, // with sudo
				'ln -sf /usr/share/zoneinfo/' + params.timezone + ' /etc/localtime', // direct symlink
				'sudo ln -sf /usr/share/zoneinfo/' + params.timezone + ' /etc/localtime', // with sudo
			];

			let lastError = null;
			for (const cmd of timezoneCommands) {
				try {
					console.log('Trying timezone command: ' + cmd);
					await execAsync(cmd);

					// Verify the change worked
					const { stdout } = await execAsync('timedatectl show --property=Timezone --value');
					const currentTimezone = stdout.trim();

					if (currentTimezone === params.timezone) {
						console.log('Successfully changed timezone to: ' + currentTimezone);
						return {
							status: 'success',
							message: 'Timezone changed to ' + params.timezone,
							data: {
								timezone: currentTimezone,
							},
						};
					} else {
						console.log('Timezone change verification failed. Expected: ' + params.timezone + ', Got: ' + currentTimezone);
					}
				} catch (error) {
					console.log('Timezone command failed: ' + cmd + ' - ' + error.message);
					lastError = error;
					continue;
				}
			}

			throw lastError || new Error('All timezone change methods failed');
		} catch (error) {
			console.error('Timezone change failed:', error);
			return {
				status: 'error',
				message: 'Failed to change timezone: ' + error.message,
			};
		}
	}

	async setAutoTimeSync(params) {
		try {
			console.log('Setting auto time sync to:', params.enabled);
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);
			const ntpCommand = params.enabled ? 'timedatectl set-ntp true' : 'timedatectl set-ntp false';
			const sudoNtpCommand = params.enabled ? 'sudo timedatectl set-ntp true' : 'sudo timedatectl set-ntp false';
			try {
				console.log('Trying command: ' + ntpCommand);
				await execAsync(ntpCommand);
			} catch (error) {
				console.log('Command failed, trying with sudo: ' + sudoNtpCommand);
				await execAsync(sudoNtpCommand);
			}
			// Verify the change
			const { stdout } = await execAsync('timedatectl status');
			const ntpEnabled = stdout.includes('NTP enabled: yes') || stdout.includes('Network time on: yes');
			return {
				status: 'success',
				message: 'Auto time sync ' + (params.enabled ? 'enabled' : 'disabled'),
				data: {
					autoSync: ntpEnabled,
					timeStatus: stdout,
				},
			};
		} catch (error) {
			console.error('Auto time sync setting failed:', error);
			return {
				status: 'error',
				message: 'Failed to set auto time sync: ' + error.message,
			};
		}
	}

	async getCurrentTimezone() {
		try {
			console.log('Getting current system timezone');
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);

			// Get current timezone from system
			const { stdout } = await execAsync('timedatectl show --property=Timezone --value');
			const currentTimezone = stdout.trim();

			if (currentTimezone) {
				console.log('Current system timezone:', currentTimezone);
				return {
					status: 'success',
					data: {
						timezone: currentTimezone,
					},
				};
			} else {
				throw new Error('Unable to get timezone from timedatectl');
			}
		} catch (error) {
			console.error('Failed to get current timezone:', error);
			return {
				status: 'error',
				message: 'Failed to get current timezone: ' + error.message,
				data: {
					timezone: 'UTC',
				},
			};
		}
	}

	async getAutoTimeSyncStatus() {
		try {
			console.log('Getting current auto time sync status');
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);

			// Get current time sync status
			const { stdout } = await execAsync('timedatectl status');
			const ntpEnabled = stdout.includes('NTP enabled: yes') || stdout.includes('Network time on: yes') || stdout.includes('NTP service: active');

			return {
				status: 'success',
				data: {
					autoSync: ntpEnabled,
					timeStatus: stdout,
				},
			};
		} catch (error) {
			console.error('Failed to get auto time sync status:', error);
			return {
				status: 'error',
				message: 'Failed to get auto time sync status: ' + error.message,
				data: {
					autoSync: false,
				},
			};
		}
	}

	async setSystemDateTime(params) {
		try {
			console.log('Setting system date and time to:', params);
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);

			if (!params.hours || !params.minutes || !params.seconds || !params.day || !params.month || !params.year) {
				throw new Error('All date and time parameters are required (hours, minutes, seconds, day, month, year)');
			}

			// Validate parameters
			const hours = parseInt(params.hours);
			const minutes = parseInt(params.minutes);
			const seconds = parseInt(params.seconds);
			const day = parseInt(params.day);
			const month = parseInt(params.month);
			const year = parseInt(params.year);

			if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59 || seconds < 0 || seconds > 59) {
				throw new Error('Invalid time values');
			}
			if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1970 || year > 2100) {
				throw new Error('Invalid date values');
			}

			// Format date and time string for timedatectl
			const formattedDate = `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
			const formattedTime = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
			const dateTimeString = `${formattedDate} ${formattedTime}`;

			// Try multiple methods to set the date/time
			const setTimeCommands = [`timedatectl set-time "${dateTimeString}"`, `sudo timedatectl set-time "${dateTimeString}"`, `date -s "${dateTimeString}"`, `sudo date -s "${dateTimeString}"`];

			let lastError = null;
			for (const cmd of setTimeCommands) {
				try {
					console.log('Trying set time command:', cmd);
					await execAsync(cmd);

					// Verify the change worked by checking current time
					const { stdout } = await execAsync('date "+%Y-%m-%d %H:%M:%S"');
					const currentDateTime = stdout.trim();

					console.log('Successfully set system date/time to:', currentDateTime);
					return {
						status: 'success',
						message: 'System date and time updated successfully',
						data: {
							dateTime: currentDateTime,
							requested: dateTimeString,
						},
					};
				} catch (error) {
					console.log('Set time command failed:', cmd, '-', error.message);
					lastError = error;
					continue;
				}
			}

			throw lastError || new Error('All date/time setting methods failed');
		} catch (error) {
			console.error('Set system date/time failed:', error);
			return {
				status: 'error',
				message: 'Failed to set system date/time: ' + error.message,
			};
		}
	}
}

module.exports = TimeManager;
