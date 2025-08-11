// Now we can use regular require with proper file system access
const CryptoHandler = require('./wallet-crypto');
const si = require('systeminformation');
const wifi = require('node-wifi');

console.log('Matchbox Wallet JavaScript runtime initialized');

// WiFi interface detection and initialization
let wifiInterface = null;
let wifiInitialized = false;
let wifiInitializing = false;
let cachedNetworks = [];
let lastScanTime = 0;
let isCurrentlyScanning = false;

// Function to detect available WiFi interfaces
async function detectWifiInterface() {
	try {
		console.log('Detecting WiFi interfaces...');

		// Try system approach first - more reliable
		const { exec } = require('child_process');
		const { promisify } = require('util');
		const execAsync = promisify(exec);

		try {
			// Use ip command to list interfaces
			const { stdout } = await execAsync('ip link show | grep -E "^[0-9]+: (wlan|wlp|wifi|wl)" | cut -d: -f2 | cut -d@ -f1 | sed "s/ //g"');
			const systemWifiInterfaces = stdout
				.trim()
				.split('\n')
				.filter((iface) => iface.length > 0);

			if (systemWifiInterfaces.length > 0) {
				wifiInterface = systemWifiInterfaces[0];
				console.log(`Found ${systemWifiInterfaces.length} WiFi interface(s) via system: ${systemWifiInterfaces.join(', ')}`);
				console.log(`Using: ${wifiInterface}`);
				return wifiInterface;
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
					/^wlp\d+s\d+/.test(iface.iface) || // wlp194s0, wlp1s0, etc.
					iface.iface.startsWith('wifi') || // wifi0, wifi1, etc.
					iface.iface.startsWith('wl') || // wl0, wl1, etc.
					iface.type === 'wireless' ||
					(iface.type && iface.type.toLowerCase().includes('wireless')));

			// Additional check - exclude virtual interfaces
			const isPhysical = !iface.iface.includes('mon') && !iface.iface.includes('ap') && !iface.virtual;

			return isWifi && isPhysical;
		});

		if (wifiInterfaces.length > 0) {
			wifiInterface = wifiInterfaces[0].iface;
			console.log(`Found ${wifiInterfaces.length} WiFi interface(s) via systeminformation. Using: ${wifiInterface}`);
			if (wifiInterfaces.length > 1) {
				console.log('Available WiFi interfaces:', wifiInterfaces.map((i) => i.iface).join(', '));
			}
			return wifiInterface;
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
async function initializeWifi() {
	if (wifiInitialized || wifiInitializing) {
		console.log('WiFi already initialized or initializing, skipping...');
		return;
	}

	wifiInitializing = true;
	console.log('Starting WiFi initialization...');

	try {
		const detectedInterface = await detectWifiInterface();
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
			new Promise((_, reject) => 
				setTimeout(() => reject(new Error('WiFi init timeout')), 5000)
			)
		]);

		wifiInitialized = true;
		console.log(`WiFi module initialized with interface: ${detectedInterface || 'auto-detect'}`);
	} catch (error) {
		console.error('WiFi initialization failed:', error);
		// Fallback to default initialization without interface
		try {
			console.log('Trying fallback initialization without interface...');
			wifi.init({
				iface: null,
			});
			wifiInitialized = true;
			console.log('WiFi fallback initialization completed');
		} catch (fallbackError) {
			console.error('WiFi fallback initialization also failed:', fallbackError);
			wifiInitialized = true; // Mark as initialized anyway to prevent hanging
		}
	} finally {
		wifiInitializing = false;
		console.log('WiFi initialization process completed');
	}
}

// Ensure WiFi is initialized before any operation
async function ensureWifiInit() {
	if (!wifiInitialized && !wifiInitializing) {
		await initializeWifi();
	}

	// Wait for initialization to complete
	while (wifiInitializing) {
		await new Promise((resolve) => setTimeout(resolve, 100));
	}
}

// Action map and message dispatcher placed first for quick overview
const HANDLERS = {
	commonPing,
	commonDelayedPing,
	systemGetBatteryInfo,
	systemCheckBatteryStatus,
	wifiScanNetworks,
	wifiGetNetworks,
	wifiConnectToNetwork,
	wifiGetConnectionStatus,
	wifiGetCurrentStrength,
	wifiGetInterfaceInfo,
	wifiReinitializeInterface,
	cryptoHash,
	cryptoGenerateKeyPair,
	cryptoGenerateRandomBytes,
	cryptoHmac,
	cryptoCreateWallet,
	cryptoWalletFromMnemonic,
	cryptoWalletFromPrivateKey,
	cryptoValidateAddress,
	cryptoKeccak256,
	cryptoGetLatestBlock,
	cryptoGetBalance,
};

global.handleMessage = async function (message, callback) {
	console.log('node.js handleMessage ', JSON.stringify(message, null, 2));
	const { messageId, action, data } = message;
	try {
		let result = {};
		const handler = HANDLERS[action];
		console.log('Handler for action', action, ':', typeof handler);
		if (typeof handler === 'function') {
			// Check if handler is async
			if (handler.constructor.name === 'AsyncFunction') {
				console.log('Calling async handler for', action);
				result = await handler(data);
			} else {
				console.log('Calling sync handler for', action);
				result = handler(data);
			}
		} else {
			console.log('No handler found for action:', action);
			result = { status: 'error', message: `Unknown action: ${action}` };
		}

		console.log('Handler result for', action, ':', result);
		if (typeof __nativeCallback === 'function') {
			__nativeCallback(messageId, result);
		}
	} catch (error) {
		console.error('Error in handleMessage for action', action, ':', error);
		const errorResult = {
			status: 'error',
			message: error.message,
			stack: error.stack,
		};

		if (typeof __nativeCallback === 'function') {
			__nativeCallback(messageId, errorResult);
		}
	}
};

// Standalone action functions
function commonPing() {
	return {
		status: 'success',
		message: 'pong',
		timestamp: Date.now(),
	};
}

async function commonDelayedPing(params = {}) {
	const delay = params?.delay || 2000;
	console.log(`Starting delayed ping with ${delay}ms delay...`);
	return new Promise((resolve) => {
		setTimeout(() => {
			console.log('Delayed ping completed!');
			resolve({
				status: 'success',
				message: 'delayed pong',
				timestamp: Date.now(),
				delay,
			});
		}, delay);
	});
}

function cryptoHash(params = {}) {
	return CryptoHandler.hash(params?.input);
}

function cryptoGenerateKeyPair() {
	return CryptoHandler.generateKeyPair();
}

function cryptoGenerateRandomBytes(params = {}) {
	return CryptoHandler.generateRandomBytes(params?.length);
}

function cryptoHmac(params = {}) {
	return CryptoHandler.hmac(params?.data, params?.key, params?.algorithm);
}

function cryptoCreateWallet() {
	return CryptoHandler.createWallet();
}

function cryptoWalletFromMnemonic(params = {}) {
	return CryptoHandler.walletFromMnemonic(params?.mnemonic);
}

function cryptoWalletFromPrivateKey(params = {}) {
	return CryptoHandler.walletFromPrivateKey(params?.privateKey);
}

function cryptoValidateAddress(params = {}) {
	return CryptoHandler.validateAddress(params?.address);
}

function cryptoKeccak256(params = {}) {
	return CryptoHandler.keccak256(params?.input);
}

async function cryptoGetLatestBlock(params = {}) {
	console.log('CryptoHandler.getLatestBlock...:', params?.rpcUrl);
	return CryptoHandler.getLatestBlock(params?.rpcUrl);
}

async function cryptoGetBalance(params = {}) {
	return CryptoHandler.getBalance(params?.address, params?.rpcUrl);
}

// WiFi management functions
async function wifiScanNetworks(params = {}) {
	console.log('wifiScanNetworks called with params:', params);
	
	try {
		console.log('About to call ensureWifiInit...');
		await ensureWifiInit();
		console.log('ensureWifiInit completed, wifiInterface:', wifiInterface);

		if (isCurrentlyScanning) {
			console.log('Scan already in progress, returning error');
			return {
				status: 'error',
				message: 'Scan already in progress',
			};
		}

		isCurrentlyScanning = true;
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
				strength: signalStrengthToBars(network.quality || network.signal_level),
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

		cachedNetworks = processedNetworks;
		lastScanTime = Date.now();
		isCurrentlyScanning = false;

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
		isCurrentlyScanning = false;
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

async function wifiGetNetworks() {
	try {
		// Return cached networks if scan was recent (less than 30 seconds ago)
		const now = Date.now();
		if (cachedNetworks.length > 0 && now - lastScanTime < 30000) {
			return {
				status: 'success',
				data: {
					networks: cachedNetworks,
					isScanning: isCurrentlyScanning,
				},
			};
		}

		// Otherwise trigger a new scan
		return await wifiScanNetworks();
	} catch (error) {
		return {
			status: 'error',
			message: error.message,
			data: {
				networks: cachedNetworks || [],
				isScanning: isCurrentlyScanning,
			},
		};
	}
}

async function wifiConnectToNetwork(params = {}) {
	try {
		await ensureWifiInit();

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
			await wifiScanNetworks();
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

async function wifiGetConnectionStatus() {
	try {
		await ensureWifiInit();

		const currentConnections = await wifi.getCurrentConnections();

		if (currentConnections && currentConnections.length > 0) {
			const connection = currentConnections[0];
			return {
				status: 'success',
				data: {
					connected: true,
					ssid: connection.ssid,
					quality: connection.quality || 0,
					strength: signalStrengthToBars(connection.quality || 0),
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

async function wifiGetCurrentStrength() {
	try {
		const status = await wifiGetConnectionStatus();
		if (status.status === 'success' && status.data.connected) {
			return {
				status: 'success',
				data: {
					strength: status.data.strength,
					quality: status.data.quality,
				},
			};
		} else {
			return {
				status: 'success',
				data: {
					strength: 0,
					quality: 0,
				},
			};
		}
	} catch (error) {
		return {
			status: 'error',
			message: error.message,
			data: {
				strength: 0,
				quality: 0,
			},
		};
	}
}

async function wifiGetInterfaceInfo() {
	try {
		const networkInterfaces = await si.networkInterfaces();

		// Get all WiFi interfaces
		const wifiInterfaces = networkInterfaces.filter((iface) => {
			const isWifi =
				iface.iface &&
				(iface.iface.startsWith('wlan') || // wlan0, wlan1, etc.
					/^wlp\d+s\d+/.test(iface.iface) || // wlp194s0, wlp1s0, etc.
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
				currentInterface: wifiInterface,
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
				currentInterface: wifiInterface,
				availableInterfaces: [],
				totalFound: 0,
			},
		};
	}
}

async function wifiReinitializeInterface(params = {}) {
	try {
		const { forceInterface } = params;

		let newInterface = forceInterface;

		if (!newInterface) {
			// Auto-detect again
			newInterface = await detectWifiInterface();
		}

		// Reinitialize WiFi module with new interface
		wifi.init({
			iface: newInterface,
		});

		wifiInterface = newInterface;

		// Clear cache to force fresh scan
		cachedNetworks = [];
		lastScanTime = 0;

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
				interface: wifiInterface,
				timestamp: Date.now(),
			},
		};
	}
}

// Helper function to convert signal quality to bars (1-4)
function signalStrengthToBars(quality) {
	if (!quality || quality <= 0) return 0;
	if (quality >= 75) return 4;
	if (quality >= 50) return 3;
	if (quality >= 25) return 2;
	return 1;
}

// System functions for battery management
async function systemGetBatteryInfo() {
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

async function systemCheckBatteryStatus() {
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
