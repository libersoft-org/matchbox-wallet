import wifi from 'node-wifi';
import si from 'systeminformation';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

class WifiManager {
	constructor() {
		this.wifiInterface = null;
		this.wifiInitialized = false;
		this.wifiInitializing = false;
		this.cachedNetworks = [];
		this.lastScanTime = 0;
		this.isCurrentlyScanning = false;
	}

	// Function to detect available WiFi interfaces
	async detectWifiInterface() {
		try {
			console.log('Detecting WiFi interfaces...');

			// Try system approach first - more reliable

			try {
				// Use ip command to list interfaces
				const { stdout } = await execAsync('ip link show | grep -E "^[0-9]+: (wlan|wlp|wifi|wl)" | cut -d: -f2 | cut -d@ -f1 | sed "s/ //g"');
				const systemWifiInterfaces = stdout
					.trim()
					.split('\n')
					.filter((iface) => iface.length > 0);

				if (systemWifiInterfaces.length > 0) {
					this.wifiInterface = systemWifiInterfaces[0];
					console.log(`Found ${systemWifiInterfaces.length} WiFi interface(s) via system: ${systemWifiInterfaces.join(', ')}`);
					console.log(`Using: ${this.wifiInterface}`);
					return this.wifiInterface;
				}
			} catch (systemError) {
				console.log('System-based detection failed, trying systeminformation...', systemError.message);
			}

			// Fallback to systeminformation
			const networkInterfaces = await si.networkInterfaces();

			// Filter for WiFi interfaces (wireless)
			const wifiInterfaces = networkInterfaces.filter((iface) => {
				// Common patterns for WiFi interface names
				const isWifi =
					iface.iface &&
					(iface.iface.startsWith('wlan') || // wlan0, wlan1, etc.
						/^wlp\d+s\d+/.test(iface.iface) || // wlp1s0, etc.
						iface.iface.startsWith('wifi') || // wifi0, wifi1, etc.
						iface.iface.startsWith('wl') || // wl0, wl1, etc.
						iface.type === 'wireless' ||
						(iface.type && iface.type.toLowerCase().includes('wireless')));

				// Additional check - exclude virtual interfaces
				const isPhysical = !iface.iface.includes('mon') && !iface.iface.includes('ap') && !iface.virtual;

				return isWifi && isPhysical;
			});

			if (wifiInterfaces.length > 0) {
				this.wifiInterface = wifiInterfaces[0].iface;
				console.log(`Found ${wifiInterfaces.length} WiFi interface(s) via systeminformation. Using: ${this.wifiInterface}`);
				if (wifiInterfaces.length > 1) {
					console.log('Available WiFi interfaces:', wifiInterfaces.map((i) => i.iface).join(', '));
				}
				return this.wifiInterface;
			} else {
				console.log('No WiFi interfaces detected, using automatic detection');
				return null;
			}
		} catch (error) {
			console.error('Error detecting WiFi interfaces:', error);
			return null;
		}
	}

	// Initialize WiFi module with detected interface
	async initializeWifi() {
		if (this.wifiInitialized || this.wifiInitializing) {
			console.log('WiFi already initialized or initializing, skipping...');
			return;
		}

		this.wifiInitializing = true;
		console.log('Starting WiFi initialization...');

		try {
			const detectedInterface = await this.detectWifiInterface();
			console.log('Detected interface:', detectedInterface);

			// Add timeout to wifi.init() to prevent hanging
			await Promise.race([
				new Promise((resolve, reject) => {
					try {
						console.log('Calling wifi.init() with interface:', detectedInterface);
						wifi.init({
							iface: detectedInterface, // use detected interface or null for automatic
						});
						console.log('wifi.init() completed successfully');
						resolve();
					} catch (error) {
						reject(error);
					}
				}),
				new Promise((_, reject) => setTimeout(() => reject(new Error('WiFi init timeout')), 5000)),
			]);

			this.wifiInitialized = true;
			console.log(`WiFi module initialized with interface: ${detectedInterface || 'auto-detect'}`);
		} catch (error) {
			console.error('WiFi initialization failed:', error);
			// Fallback to default initialization without interface
			try {
				console.log('Trying fallback initialization without interface...');
				wifi.init({
					iface: null,
				});
				this.wifiInitialized = true;
				console.log('WiFi fallback initialization completed');
			} catch (fallbackError) {
				console.error('WiFi fallback initialization also failed:', fallbackError);
				this.wifiInitialized = true; // Mark as initialized anyway to prevent hanging
			}
		} finally {
			this.wifiInitializing = false;
			console.log('WiFi initialization process completed');
		}
	}

	// Ensure WiFi is initialized before any operation
	async ensureWifiInit() {
		//console.log('ensureWifiInit called at', new Date().toISOString());
		//console.log('Current state - wifiInitialized:', this.wifiInitialized, 'wifiInitializing:', this.wifiInitializing);
		if (!this.wifiInitialized && !this.wifiInitializing) {
			//console.log('WiFi not initialized, starting initialization...');
			await this.initializeWifi();
		}
		// Wait for initialization to complete
		let waitCount = 0;
		while (this.wifiInitializing) {
			waitCount++;
			//console.log(`Waiting for WiFi initialization to complete... (attempt ${waitCount})`);
			await new Promise((resolve) => setTimeout(resolve, 100));
			if (waitCount > 50) {
				// Safety check - max 5 seconds wait
				console.error('WiFi initialization timeout - breaking out of wait loop');
				this.wifiInitializing = false;
				break;
			}
		}
		//console.log('WiFi initialization check complete, final state - wifiInitialized:', this.wifiInitialized, 'wifiInitializing:', this.wifiInitializing);
	}

	// Helper function to convert signal quality to bars (1-4)
	signalStrengthToBars(quality) {
		if (!quality || quality <= 0) return 0;
		if (quality >= 75) return 4;
		if (quality >= 50) return 3;
		if (quality >= 25) return 2;
		return 1;
	}

	async scanNetworks(params = {}) {
		console.log('wifiScanNetworks called with params:', params);

		try {
			console.log('About to call ensureWifiInit...');
			await this.ensureWifiInit();
			console.log('ensureWifiInit completed, wifiInterface:', this.wifiInterface);

			if (this.isCurrentlyScanning) {
				console.log('Scan already in progress, returning error');
				return {
					status: 'error',
					message: 'Scan already in progress',
				};
			}

			this.isCurrentlyScanning = true;
			console.log('Starting WiFi scan...');

			// Add timeout to prevent hanging scans
			const scanPromise = wifi.scan();
			const timeoutPromise = new Promise((_, reject) => {
				setTimeout(() => reject(new Error('WiFi scan timeout after 8 seconds')), 8000);
			});

			// Use node-wifi with timeout protection
			const networks = await Promise.race([scanPromise, timeoutPromise]);
			console.log('Raw wifi.scan() result:', networks);

			// Process networks - convert to format expected by QML
			const processedNetworks = networks
				.map((network) => ({
					name: network.ssid,
					strength: this.signalStrengthToBars(network.quality || network.signal_level),
					secured: network.security !== 'none' && network.security !== '',
					connected: false, // Will be updated by connection status check
				}))
				.filter((network) => network.name && network.name.trim() !== '') // Filter out empty SSIDs
				.sort((a, b) => b.strength - a.strength); // Sort by signal strength

			console.log('Processed networks:', processedNetworks);

			// Check which network is currently connected
			try {
				const currentConnections = await wifi.getCurrentConnections();
				console.log('Current connections:', currentConnections);
				if (currentConnections && currentConnections.length > 0) {
					const connectedSSID = currentConnections[0].ssid;
					processedNetworks.forEach((network) => {
						if (network.name === connectedSSID) {
							network.connected = true;
						}
					});
				}
			} catch (connError) {
				console.log('Could not get current connections:', connError.message);
			}

			this.cachedNetworks = processedNetworks;
			this.lastScanTime = Date.now();
			this.isCurrentlyScanning = false;

			console.log(`Found ${processedNetworks.length} WiFi networks`);

			const result = {
				status: 'success',
				data: {
					networks: processedNetworks,
					isScanning: false,
				},
			};

			console.log('wifiScanNetworks returning result:', result);
			return result;
		} catch (error) {
			this.isCurrentlyScanning = false;
			console.error('WiFi scan failed:', error);
			return {
				status: 'error',
				message: error.message,
				data: {
					networks: [],
					isScanning: false,
				},
			};
		}
	}

	async getNetworks() {
		try {
			// Return cached networks if scan was recent (less than 30 seconds ago)
			const now = Date.now();
			if (this.cachedNetworks.length > 0 && now - this.lastScanTime < 30000) {
				return {
					status: 'success',
					data: {
						networks: this.cachedNetworks,
						isScanning: this.isCurrentlyScanning,
					},
				};
			}

			// Otherwise trigger a new scan
			return await this.scanNetworks();
		} catch (error) {
			return {
				status: 'error',
				message: error.message,
				data: {
					networks: this.cachedNetworks || [],
					isScanning: this.isCurrentlyScanning,
				},
			};
		}
	}

	async connectToNetwork(params = {}) {
		try {
			await this.ensureWifiInit();

			const { ssid, password } = params;

			if (!ssid) {
				return {
					status: 'error',
					message: 'SSID is required',
				};
			}

			console.log(`Attempting to connect to WiFi network: ${ssid}`);

			const connection = {
				ssid: ssid,
			};

			if (password && password.trim() !== '') {
				connection.password = password;
			}

			await wifi.connect(connection);

			console.log(`Successfully connected to ${ssid}`);

			// Update cached networks to reflect new connection
			setTimeout(async () => {
				await this.scanNetworks();
			}, 2000);

			return {
				status: 'success',
				message: `Connected to ${ssid}`,
				data: {
					ssid: ssid,
					connected: true,
				},
			};
		} catch (error) {
			console.error('WiFi connection failed:', error);
			return {
				status: 'error',
				message: error.message,
				data: {
					ssid: params?.ssid,
					connected: false,
				},
			};
		}
	}

	async disconnect() {
		try {
			await this.ensureWifiInit();

			console.log('Attempting to disconnect from WiFi network');

			// Get current connection before disconnecting
			let currentSSID = null;
			try {
				const currentConnections = await wifi.getCurrentConnections();
				if (currentConnections && currentConnections.length > 0) {
					currentSSID = currentConnections[0].ssid;
				}
			} catch (error) {
				console.log('Could not get current connection before disconnect:', error.message);
			}

			// Disconnect from WiFi
			await wifi.disconnect();

			console.log(`Successfully disconnected from WiFi${currentSSID ? ` (was connected to: ${currentSSID})` : ''}`);

			// Update cached networks to reflect disconnection
			setTimeout(async () => {
				await this.scanNetworks();
			}, 2000);

			return {
				status: 'success',
				message: `Disconnected from WiFi${currentSSID ? ` (${currentSSID})` : ''}`,
				data: {
					ssid: currentSSID,
					connected: false,
				},
			};
		} catch (error) {
			console.error('WiFi disconnection failed:', error);
			return {
				status: 'error',
				message: error.message,
				data: {
					connected: true, // Assume still connected if disconnect failed
				},
			};
		}
	}

	async getConnectionStatus() {
		//console.log('getConnectionStatus called at', new Date().toISOString());
		try {
			//console.log('About to call ensureWifiInit from getConnectionStatus...');
			await this.ensureWifiInit();
			//console.log('ensureWifiInit completed in getConnectionStatus');
			//console.log('About to call wifi.getCurrentConnections...');
			const currentConnections = await wifi.getCurrentConnections();
			//console.log('wifi.getCurrentConnections returned:', currentConnections);
			console.log('Updating WiFi connection status');
			if (currentConnections && currentConnections.length > 0) {
				const connection = currentConnections[0];
				return {
					status: 'success',
					data: {
						connected: true,
						ssid: connection.ssid,
						quality: connection.quality || 0,
						strength: this.signalStrengthToBars(connection.quality || 0),
						security: connection.security || 'unknown',
					},
				};
			} else {
				return {
					status: 'success',
					data: {
						connected: false,
						ssid: null,
						quality: 0,
						strength: 0,
						security: null,
					},
				};
			}
		} catch (error) {
			console.error('Failed to get connection status:', error);
			return {
				status: 'error',
				message: error.message,
				data: {
					connected: false,
					ssid: null,
					quality: 0,
					strength: 0,
					security: null,
				},
			};
		}
	}

	async getCurrentStrength() {
		//console.log('getCurrentStrength called at', new Date().toISOString());
		//console.log('wifiInitialized:', this.wifiInitialized, 'wifiInitializing:', this.wifiInitializing);
		try {
			//console.log('About to call getConnectionStatus...');
			const status = await this.getConnectionStatus();
			//console.log('getConnectionStatus returned:', JSON.stringify(status));
			if (status.status === 'success' && status.data.connected) {
				const result = {
					status: 'success',
					data: {
						strength: status.data.strength,
						quality: status.data.quality,
					},
				};
				//console.log('getCurrentStrength returning connected result:', result);
				return result;
			} else {
				const result = {
					status: 'success',
					data: {
						strength: 0,
						quality: 0,
					},
				};
				//console.log('getCurrentStrength returning disconnected result:', result);
				return result;
			}
		} catch (error) {
			console.error('getCurrentStrength caught error:', error);
			const result = {
				status: 'error',
				message: error.message,
				data: {
					strength: 0,
					quality: 0,
				},
			};
			//console.log('getCurrentStrength returning error result:', result);
			return result;
		}
	}

	async getInterfaceInfo() {
		try {
			const networkInterfaces = await si.networkInterfaces();

			// Get all WiFi interfaces
			const wifiInterfaces = networkInterfaces.filter((iface) => {
				const isWifi =
					iface.iface &&
					(iface.iface.startsWith('wlan') || // wlan0, wlan1, etc.
						/^wlp\d+s\d+/.test(iface.iface) || // wlp1s0, etc.
						iface.iface.startsWith('wifi') || // wifi0, wifi1, etc.
						iface.iface.startsWith('wl') || // wl0, wl1, etc.
						iface.type === 'wireless' ||
						(iface.type && iface.type.toLowerCase().includes('wireless')));

				const isPhysical = !iface.iface.includes('mon') && !iface.iface.includes('ap') && !iface.virtual;

				return isWifi && isPhysical;
			});

			return {
				status: 'success',
				data: {
					currentInterface: this.wifiInterface,
					availableInterfaces: wifiInterfaces.map((iface) => ({
						name: iface.iface,
						mac: iface.mac,
						ip4: iface.ip4,
						ip6: iface.ip6,
						state: iface.operstate,
						type: iface.type,
						speed: iface.speed,
					})),
					totalFound: wifiInterfaces.length,
				},
			};
		} catch (error) {
			return {
				status: 'error',
				message: error.message,
				data: {
					currentInterface: this.wifiInterface,
					availableInterfaces: [],
					totalFound: 0,
				},
			};
		}
	}

	async reinitializeInterface(params = {}) {
		try {
			const { forceInterface } = params;

			let newInterface = forceInterface;

			if (!newInterface) {
				// Auto-detect again
				newInterface = await this.detectWifiInterface();
			}

			// Reinitialize WiFi module with new interface
			wifi.init({
				iface: newInterface,
			});

			this.wifiInterface = newInterface;

			// Clear cache to force fresh scan
			this.cachedNetworks = [];
			this.lastScanTime = 0;

			console.log(`WiFi module reinitialized with interface: ${newInterface || 'auto-detect'}`);

			return {
				status: 'success',
				message: `WiFi reinitialized with interface: ${newInterface || 'auto-detect'}`,
				data: {
					interface: newInterface,
					timestamp: Date.now(),
				},
			};
		} catch (error) {
			console.error('WiFi reinitialization failed:', error);
			return {
				status: 'error',
				message: error.message,
				data: {
					interface: this.wifiInterface,
					timestamp: Date.now(),
				},
			};
		}
	}
}

export default WifiManager;
