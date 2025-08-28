import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

class PowerManager {
	async reboot() {
		try {
			console.log('System reboot requested');

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
					console.log('Trying reboot command: ' + cmd);
					await execAsync(cmd);
					return {
						status: 'success',
						message: 'System reboot initiated with: ' + cmd,
					};
				} catch (error) {
					console.log('Reboot command failed: ' + cmd + ' - ' + error.message);
					lastError = error;
					continue;
				}
			}

			throw lastError || new Error('All reboot methods failed');
		} catch (error) {
			console.error('Reboot failed:', error);
			return {
				status: 'error',
				message: 'Failed to reboot system: ' + error.message,
			};
		}
	}

	async shutdown() {
		try {
			console.log('System shutdown requested');

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
					console.log('Trying shutdown command: ' + cmd);
					await execAsync(cmd);
					return {
						status: 'success',
						message: 'System shutdown initiated with: ' + cmd,
					};
				} catch (error) {
					console.log('Shutdown command failed: ' + cmd + ' - ' + error.message);
					lastError = error;
					continue;
				}
			}

			throw lastError || new Error('All shutdown methods failed');
		} catch (error) {
			console.error('Shutdown failed:', error);
			return {
				status: 'error',
				message: 'Failed to shutdown system: ' + error.message,
			};
		}
	}
}

export default PowerManager;
