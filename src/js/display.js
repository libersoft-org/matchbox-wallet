class DisplayManager {
	async getBrightness() {
		try {
			const { exec } = require('child_process');
			const { promisify } = require('util');
			const execAsync = promisify(exec);
			console.log('Getting brightness using brightnessctl');
			const { stdout } = await execAsync('brightnessctl get');
			const currentBrightness = parseInt(stdout.trim()) || 0;
			const { stdout: maxBrightnessOutput } = await execAsync('brightnessctl max');
			const maxBrightness = parseInt(maxBrightnessOutput.trim()) || 255;
			const brightnessPercentage = Math.round((currentBrightness / maxBrightness) * 100);
			return {
				status: 'success',
				message: 'Brightness retrieved successfully using brightnessctl',
				data: {
					brightness: Math.min(100, Math.max(0, brightnessPercentage)),
				},
			};
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
			console.log('Setting system brightness to ' + brightness + '%');
			await execAsync('brightnessctl set ' + brightness + '%');
			const verifyResult = await this.getBrightness();
			return {
				status: 'success',
				message: 'Brightness set to ' + brightness + '% using brightnessctl',
				data: {
					brightness: brightness,
					actualBrightness: verifyResult.data?.brightness || brightness,
				},
			};
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
