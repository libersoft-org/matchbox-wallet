const CryptoManager = require('./crypto.js');
const WifiManager = require('./wifi.js');
const SystemManager = require('./system.js');
const TestManager = require('./test.js');

// Initialize managers
const cryptoManager = new CryptoManager();
const wifiManager = new WifiManager();
const systemManager = new SystemManager();
const testManager = new TestManager();

console.log('Matchbox Wallet JavaScript runtime initialized');

// Action map and message dispatcher placed first for quick overview
const HANDLERS = {
	testPing,
	testDelayedPing,
	systemGetBatteryInfo,
	systemCheckBatteryStatus,
	systemReboot,
	systemShutdown,
	wifiScanNetworks,
	wifiGetNetworks,
	wifiConnectToNetwork,
	wifiDisconnect,
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

// Test management functions - wrapper functions calling TestManager
function testPing() {
	return testManager.ping();
}

async function testDelayedPing(params = {}) {
	return await testManager.delayedPing(params);
}

// Crypto management functions - wrapper functions calling CryptoManager
function cryptoHash(params = {}) {
	return cryptoManager.hash(params);
}

function cryptoGenerateKeyPair() {
	return cryptoManager.generateKeyPair();
}

function cryptoGenerateRandomBytes(params = {}) {
	return cryptoManager.generateRandomBytes(params);
}

function cryptoHmac(params = {}) {
	return cryptoManager.hmac(params);
}

function cryptoCreateWallet() {
	return cryptoManager.createWallet();
}

function cryptoWalletFromMnemonic(params = {}) {
	return cryptoManager.walletFromMnemonic(params);
}

function cryptoWalletFromPrivateKey(params = {}) {
	return cryptoManager.walletFromPrivateKey(params);
}

function cryptoValidateAddress(params = {}) {
	return cryptoManager.validateAddress(params);
}

function cryptoKeccak256(params = {}) {
	return cryptoManager.keccak256(params);
}

async function cryptoGetLatestBlock(params = {}) {
	return await cryptoManager.getLatestBlock(params);
}

async function cryptoGetBalance(params = {}) {
	return await cryptoManager.getBalance(params);
}

// WiFi management functions - wrapper functions calling WifiManager
async function wifiScanNetworks(params = {}) {
	return await wifiManager.scanNetworks(params);
}

async function wifiGetNetworks() {
	return await wifiManager.getNetworks();
}

async function wifiConnectToNetwork(params = {}) {
	return await wifiManager.connectToNetwork(params);
}

async function wifiDisconnect() {
	return await wifiManager.disconnect();
}

async function wifiGetConnectionStatus() {
	return await wifiManager.getConnectionStatus();
}

async function wifiGetCurrentStrength() {
	return await wifiManager.getCurrentStrength();
}

async function wifiGetInterfaceInfo() {
	return await wifiManager.getInterfaceInfo();
}

async function wifiReinitializeInterface(params = {}) {
	return await wifiManager.reinitializeInterface(params);
}

// System management functions - wrapper functions calling SystemManager
async function systemGetBatteryInfo() {
	return await systemManager.getBatteryInfo();
}

async function systemCheckBatteryStatus() {
	return await systemManager.checkBatteryStatus();
}

async function systemReboot() {
	return await systemManager.reboot();
}

async function systemShutdown() {
	return await systemManager.shutdown();
}
