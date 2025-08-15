const fs = require('fs');
const https = require('https');
const { execSync } = require('child_process');

class SystemManager {
	/**
	 * Get current Debian system version from /etc/debian_version
	 */
	getCurrentSystemVersion() {
		try {
			const version = fs.readFileSync('/etc/debian_version', 'utf8').trim();
			return {
				status: 'success',
				data: {
					version: version,
					fullVersion: `Debian ${version}`,
				},
			};
		} catch (error) {
			console.error('Error reading Debian version:', error);
			return {
				status: 'error',
				message: 'Failed to read system version',
				error: error.message,
			};
		}
	}

	/**
	 * Get latest stable Debian version from official repository
	 */
	async getLatestSystemVersion() {
		return new Promise((resolve) => {
			const url = 'https://deb.debian.org/debian/dists/stable/Release';

			https
				.get(url, (response) => {
					let data = '';

					response.on('data', (chunk) => {
						data += chunk;
					});

					response.on('end', () => {
						try {
							// Look for Version: line
							const versionMatch = data.match(/^Version:\s*(.+)$/m);

							if (versionMatch) {
								const version = versionMatch[1].trim();
								resolve({
									status: 'success',
									data: {
										version: version,
										fullVersion: `Debian ${version}`,
									},
								});
							} else {
								resolve({
									status: 'error',
									message: 'Version information not found in release file',
								});
							}
						} catch (error) {
							console.error('Error parsing release data:', error);
							resolve({
								status: 'error',
								message: 'Failed to parse version information',
								error: error.message,
							});
						}
					});
				})
				.on('error', (error) => {
					console.error('Error fetching latest version:', error);
					resolve({
						status: 'error',
						message: 'Failed to fetch latest version information',
						error: error.message,
					});
				});
		});
	}

	async getLatestApplicationVersion() {
		// TODO: This is a mock implementation, in reality, you would check your application's update server
		return {
			status: 'success',
			data: {
				version: '0.0.2',
			},
		};
	}
}

export default SystemManager;
