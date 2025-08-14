const { execSync, exec } = require('child_process');
const fs = require('fs');

class FirewallManager {
	// Get current firewall status
	async getFirewallStatus() {
		try {
			const status = execSync('ufw status', { encoding: 'utf8' });
			const isEnabled = status.includes('Status: active');

			// Parse existing rules
			const rules = this.parseUfwRules(status);

			return {
				status: 'success',
				data: {
					enabled: isEnabled,
					rules: rules,
				},
			};
		} catch (error) {
			console.error('Error getting firewall status:', error);
			return {
				status: 'error',
				message: 'Failed to get firewall status',
				error: error.message,
			};
		}
	}

	/**
	 * Parse UFW rules output
	 */
	parseUfwRules(statusOutput) {
		const lines = statusOutput.split('\n');
		const rules = [];
		let inRulesSection = false;

		for (const line of lines) {
			if (line.includes('--')) {
				inRulesSection = true;
				continue;
			}

			if (inRulesSection && line.trim()) {
				const parts = line.trim().split(/\s+/);
				if (parts.length >= 2) {
					const portMatch = parts[0].match(/^(\d+)(\/tcp|\/udp)?$/);
					if (portMatch) {
						// Extract comment after # symbol
						const commentIndex = line.indexOf('#');
						const description = commentIndex !== -1 ? line.substring(commentIndex + 1).trim() : `Port ${portMatch[1]}`;

						rules.push({
							port: parseInt(portMatch[1]),
							protocol: portMatch[2] ? portMatch[2].substring(1) : 'tcp',
							action: parts[1].toLowerCase(),
							description: description,
						});
					}
				}
			}
		}

		return rules;
	}

	/**
	 * Enable or disable firewall
	 */
	async setFirewallEnabled(enabled) {
		try {
			if (enabled) {
				// Enable UFW with default deny incoming, allow outgoing
				execSync('ufw --force reset', { stdio: 'pipe' });
				execSync('ufw default deny incoming', { stdio: 'pipe' });
				execSync('ufw default allow outgoing', { stdio: 'pipe' });
				execSync('ufw --force enable', { stdio: 'pipe' });
			} else {
				execSync('ufw --force disable', { stdio: 'pipe' });
			}

			return {
				status: 'success',
				message: `Firewall ${enabled ? 'enabled' : 'disabled'} successfully`,
			};
		} catch (error) {
			console.error('Error setting firewall status:', error);
			return {
				status: 'error',
				message: `Failed to ${enabled ? 'enable' : 'disable'} firewall`,
				error: error.message,
			};
		}
	}

	/**
	 * Add a new firewall rule
	 */
	async addException(port, protocol = 'tcp', description = '') {
		try {
			// Validate port number
			const portNum = parseInt(port);
			if (isNaN(portNum) || portNum < 1 || portNum > 65535) {
				return {
					status: 'error',
					message: 'Invalid port number. Must be between 1 and 65535.',
				};
			}

			// Validate protocol
			if (!['tcp', 'udp'].includes(protocol.toLowerCase())) {
				return {
					status: 'error',
					message: 'Invalid protocol. Must be tcp or udp.',
				};
			}

			// Add the rule with comment
			const finalDescription = description || `Port ${portNum}`;
			const command = `ufw allow ${portNum}/${protocol.toLowerCase()} comment '${finalDescription}'`;
			execSync(command, { stdio: 'pipe' });

			return {
				status: 'success',
				message: `Port ${portNum}/${protocol} added successfully`,
				data: {
					port: portNum,
					protocol: protocol.toLowerCase(),
					description: finalDescription,
					enabled: true,
				},
			};
		} catch (error) {
			console.error('Error adding port:', error);
			return {
				status: 'error',
				message: 'Failed to add port',
				error: error.message,
			};
		}
	}

	/**
	 * Enable or disable a specific port
	 */
	async setExceptionEnabled(port, protocol = 'tcp', enabled = true, description = '') {
		try {
			const portNum = parseInt(port);
			if (isNaN(portNum) || portNum < 1 || portNum > 65535) {
				return {
					status: 'error',
					message: 'Invalid port number. Must be between 1 and 65535.',
				};
			}

			// Validate protocol
			if (!['tcp', 'udp'].includes(protocol.toLowerCase())) {
				return {
					status: 'error',
					message: 'Invalid protocol. Must be tcp or udp.',
				};
			}

			const action = enabled ? 'allow' : 'deny';
			const finalDescription = description || `Port ${portNum}`;

			// Use UFW to allow or deny the port with comment
			execSync(`ufw ${action} ${portNum}/${protocol.toLowerCase()} comment '${finalDescription}'`, { stdio: 'pipe' });

			return {
				status: 'success',
				message: `Port ${portNum}/${protocol} ${enabled ? 'enabled' : 'disabled'} successfully`,
				data: {
					port: portNum,
					protocol: protocol.toLowerCase(),
					description: finalDescription,
					enabled: enabled,
				},
			};
		} catch (error) {
			console.error('Error setting port status:', error);
			return {
				status: 'error',
				message: `Failed to ${enabled ? 'enable' : 'disable'} port`,
				error: error.message,
			};
		}
	}

	/**
	 * Remove a firewall rule
	 */
	async removeException(port, protocol = 'tcp') {
		try {
			const portNum = parseInt(port);
			if (isNaN(portNum)) {
				return {
					status: 'error',
					message: 'Invalid port number',
				};
			}

			// Remove the rule
			const command = `ufw delete allow ${portNum}/${protocol.toLowerCase()}`;
			execSync(command, { stdio: 'pipe' });

			return {
				status: 'success',
				message: `Port ${portNum}/${protocol} removed successfully`,
			};
		} catch (error) {
			console.error('Error removing port:', error);
			return {
				status: 'error',
				message: 'Failed to remove port',
				error: error.message,
			};
		}
	}

	/**
	 * Reset firewall to default configuration
	 */
	async resetToDefaults() {
		try {
			// Reset UFW
			execSync('ufw --force reset', { stdio: 'pipe' });
			execSync('ufw default deny incoming', { stdio: 'pipe' });
			execSync('ufw default allow outgoing', { stdio: 'pipe' });

			// Add default enabled ports
			for (const defaultPort of this.defaultPorts) {
				if (defaultPort.enabled) {
					await this.addException(defaultPort.port, defaultPort.protocol, defaultPort.description);
				}
			}

			execSync('ufw --force enable', { stdio: 'pipe' });

			return {
				status: 'success',
				message: 'Firewall reset to defaults successfully',
			};
		} catch (error) {
			console.error('Error resetting firewall:', error);
			return {
				status: 'error',
				message: 'Failed to reset firewall',
				error: error.message,
			};
		}
	}
}

module.exports = FirewallManager;
