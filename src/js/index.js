// Now we can use regular require with proper file system access
const CryptoHandler = require('./wallet-crypto');
const si = require('systeminformation');

console.log('Matchbox Wallet JavaScript runtime initialized');

// Action map and message dispatcher placed first for quick overview
const HANDLERS = {
	commonPing,
	commonDelayedPing,
	systemGetBatteryInfo,
	systemCheckBatteryStatus,
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
		if (typeof handler === 'function') {
			// Check if handler is async
			if (handler.constructor.name === 'AsyncFunction') {
				result = await handler(data);
			} else {
				result = handler(data);
			}
		} else {
			result = { status: 'error', message: `Unknown action: ${action}` };
		}
		
		if (typeof __nativeCallback === 'function') {
			__nativeCallback(messageId, result);
		}
	} catch (error) {
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
				additionalBatteries: battery.additionalBatteries || []
			}
		};
	} catch (error) {
		return {
			status: 'error',
			message: error.message,
			data: {
				hasBattery: false,
				batteryLevel: 0,
				charging: false
			}
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
				hasBattery: battery.hasBattery
			}
		};
	} catch (error) {
		return {
			status: 'error',
			message: error.message,
			data: {
				batteryLevel: 0,
				charging: false,
				hasBattery: false
			}
		};
	}
}
