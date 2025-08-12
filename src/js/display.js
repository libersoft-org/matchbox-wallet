class DisplayManager {
	async getBrightness() {
		try {
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);

			// Try different methods to get brightness
			const brightnessCommands = ['cat /sys/class/backlight/*/brightness 2>/dev/null | head -1', "xrandr --verbose | grep -i brightness | head -1 | awk '{print $2}' | awk '{print int($1 * 100)}'", 'ddcutil getvcp 10 2>/dev/null | grep -o "current value = [0-9]*" | grep -o "[0-9]*"'];

			let lastError = null;
			for (const cmd of brightnessCommands) {
				try {
					console.log('Trying brightness command: ' + cmd);
					const { stdout } = await execAsync(cmd);
					let brightness = parseInt(stdout.trim()) || 50;

					// For backlight systems, we need to convert from actual value to percentage
					if (cmd.includes('/sys/class/backlight/')) {
						try {
							const { stdout: maxBrightness } = await execAsync('cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1');
							const maxValue = parseInt(maxBrightness.trim()) || 255;
							brightness = Math.round((brightness / maxValue) * 100);
						} catch (e) {
							// Fallback: assume 255 is max
							brightness = Math.round((brightness / 255) * 100);
						}
					}

					return {
						status: 'success',
						message: 'Brightness retrieved successfully',
						data: {
							brightness: Math.min(100, Math.max(0, brightness)),
						},
					};
				} catch (error) {
					console.log('Brightness command failed: ' + cmd + ' - ' + error.message);
					lastError = error;
					continue;
				}
			}

			throw lastError || new Error('All brightness retrieval methods failed');
		} catch (error) {
			console.error('Get brightness failed:', error);
			return {
				status: 'error',
				message: 'Failed to get system brightness: ' + error.message,
				data: {
					brightness: 50, // Default fallback brightness
				},
			};
		}
	}

	async setBrightness(params) {
		try {
			const brightness = parseInt(params.brightness);
			if (isNaN(brightness) || brightness < 0 || brightness > 100) throw new Error('Invalid brightness level. Must be between 0 and 100.');
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);
			console.log(`Setting system brightness to ${brightness}%`);
			// Try different methods to set brightness
			const brightnessCommands = [];

			// Method 1: Using backlight interface
			try {
				const { stdout: maxBrightness } = await execAsync('cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1');
				const maxValue = parseInt(maxBrightness.trim()) || 255;
				const actualValue = Math.round((brightness / 100) * maxValue);
				brightnessCommands.push(`echo ${actualValue} | sudo tee /sys/class/backlight/*/brightness`);
			} catch (e) {
				console.log('Could not get max brightness for backlight interface');
			}

			// Method 2: Using xrandr (for X11 systems)
			brightnessCommands.push(`xrandr --output \$(xrandr | grep " connected" | head -1 | awk '{print $1}') --brightness ${brightness / 100}`);

			// Method 3: Using ddcutil (for external monitors)
			brightnessCommands.push(`ddcutil setvcp 10 ${brightness}`);

			// Method 4: Using light utility if available
			brightnessCommands.push(`light -S ${brightness}`);

			let lastError = null;
			for (const cmd of brightnessCommands) {
				try {
					console.log('Trying brightness set command: ' + cmd);
					await execAsync(cmd);

					// Verify the brightness was set by trying to read it back
					const verifyResult = await this.getBrightness();

					return {
						status: 'success',
						message: `Brightness set to ${brightness}% using: ${cmd}`,
						data: {
							brightness: brightness,
							actualBrightness: verifyResult.data?.brightness || brightness,
						},
					};
				} catch (error) {
					console.log('Brightness set command failed: ' + cmd + ' - ' + error.message);
					lastError = error;
					continue;
				}
			}

			throw lastError || new Error('All brightness setting methods failed');
		} catch (error) {
			console.error('Set brightness failed:', error);
			return {
				status: 'error',
				message: 'Failed to set system brightness: ' + error.message,
			};
		}
	}
}

module.exports = DisplayManager;
