class AudioManager {
	async getVolume() {
		try {
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);

			// Try different methods to get volume
			const volumeCommands = ['amixer get Master | grep -o "[0-9]*%" | head -1 | tr -d "%"'];

			let lastError = null;
			for (const cmd of volumeCommands) {
				try {
					console.log('Trying volume command: ' + cmd);
					const { stdout } = await execAsync(cmd);
					const volume = parseInt(stdout.trim()) || 0;

					return {
						status: 'success',
						message: 'Volume retrieved successfully',
						data: {
							volume: Math.min(100, Math.max(0, volume)),
						},
					};
				} catch (error) {
					console.log('Volume command failed: ' + cmd + ' - ' + error.message);
					lastError = error;
					continue;
				}
			}

			throw lastError || new Error('All volume retrieval methods failed');
		} catch (error) {
			console.error('Get volume failed:', error);
			return {
				status: 'error',
				message: 'Failed to get system volume: ' + error.message,
				data: {
					volume: 50, // Default fallback volume
				},
			};
		}
	}

	async setVolume(params) {
		try {
			const volume = parseInt(params.volume);
			if (isNaN(volume) || volume < 0 || volume > 100) {
				throw new Error('Invalid volume level. Must be between 0 and 100.');
			}

			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);

			console.log(`Setting system volume to ${volume}%`);

			// First try to detect available audio devices
			try {
				const devices = await execAsync('amixer controls | grep -i master');
				console.log('Available audio controls:', devices.stdout);
			} catch (e) {
				console.log('Could not list audio controls:', e.message);
			}

			// Try different methods to set volume
			const volumeCommands = [`amixer sset Master ${volume}%`, `amixer -q sset Master ${volume}%`, `pactl set-sink-volume @DEFAULT_SINK@ ${volume}%`, `amixer -c 0 sset Master ${volume}%`, `amixer -D pulse sset Master ${volume}%`, `alsactl --file /tmp/asound.state store && amixer sset Master ${volume}% && alsactl --file /tmp/asound.state restore`];

			let lastError = null;
			for (const cmd of volumeCommands) {
				try {
					console.log('Trying volume set command: ' + cmd);
					await execAsync(cmd);

					// Verify the volume was set by trying to read it back
					const verifyResult = await this.getVolume();

					return {
						status: 'success',
						message: `Volume set to ${volume}% using: ${cmd}`,
						data: {
							volume: volume,
							actualVolume: verifyResult.data?.volume || volume,
						},
					};
				} catch (error) {
					console.log('Volume set command failed: ' + cmd + ' - ' + error.message);
					lastError = error;
					continue;
				}
			}

			throw lastError || new Error('All volume setting methods failed');
		} catch (error) {
			console.error('Set volume failed:', error);
			return {
				status: 'error',
				message: 'Failed to set system volume: ' + error.message,
			};
		}
	}
}

module.exports = AudioManager;
