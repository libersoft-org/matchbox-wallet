const CryptoManager = require('./crypto.js');
const WifiManager = require('./wifi.js');
const BatteryManager = require('./battery.js');
const PowerManager = require('./power.js');
const TimeManager = require('./time.js');
const AudioManager = require('./audio.js');
const DisplayManager = require('./display.js');
const TestManager = require('./test.js');
const SystemManager = require('./system.js');
const cryptoManager = new CryptoManager();
const wifiManager = new WifiManager();
const batteryManager = new BatteryManager();
const powerManager = new PowerManager();
const timeManager = new TimeManager();
const audioManager = new AudioManager();
const displayManager = new DisplayManager();
const testManager = new TestManager();
const systemManager = new SystemManager();

const HANDLERS = {
	testPing: () => testManager.ping(),
	testDelayedPing: (params) => testManager.delayedPing(params),
	batteryGetInfo: () => batteryManager.getBatteryInfo(),
	batteryCheckStatus: () => batteryManager.checkBatteryStatus(),
	powerReboot: () => powerManager.reboot(),
	powerShutdown: () => powerManager.shutdown(),
	timeListTimeZones: () => timeManager.listTimeZones(),
	timeChangeTimeZone: (params) => timeManager.changeTimeZone(params),
	timeSyncTime: () => timeManager.syncTime(),
	timeSetAutoTimeSync: (params) => timeManager.setAutoTimeSync(params),
	audioGetVolume: () => audioManager.getVolume(),
	audioSetVolume: (params) => audioManager.setVolume(params),
	displayGetBrightness: () => displayManager.getBrightness(),
	displaySetBrightness: (params) => displayManager.setBrightness(params),
	wifiScanNetworks: (params) => wifiManager.scanNetworks(params),
	wifiGetNetworks: () => wifiManager.getNetworks(),
	wifiConnectToNetwork: (params) => wifiManager.connectToNetwork(params),
	wifiDisconnect: () => wifiManager.disconnect(),
	wifiGetConnectionStatus: () => wifiManager.getConnectionStatus(),
	wifiGetCurrentStrength: () => wifiManager.getCurrentStrength(),
	wifiGetInterfaceInfo: () => wifiManager.getInterfaceInfo(),
	wifiReinitializeInterface: (params) => wifiManager.reinitializeInterface(params),
	systemGetCurrentVersion: () => systemManager.getCurrentSystemVersion(),
	systemGetLatestVersion: () => systemManager.getLatestSystemVersion(),
	systemGetLatestAppVersion: () => systemManager.getLatestApplicationVersion(),
	cryptoHash: (params) => cryptoManager.hash(params),
	cryptoGenerateKeyPair: () => cryptoManager.generateKeyPair(),
	cryptoGenerateRandomBytes: (params) => cryptoManager.generateRandomBytes(params),
	cryptoHmac: (params) => cryptoManager.hmac(params),
	cryptoCreateWallet: () => cryptoManager.createWallet(),
	cryptoWalletFromMnemonic: (params) => cryptoManager.walletFromMnemonic(params),
	cryptoWalletFromPrivateKey: (params) => cryptoManager.walletFromPrivateKey(params),
	cryptoValidateAddress: (params) => cryptoManager.validateAddress(params),
	cryptoKeccak256: (params) => cryptoManager.keccak256(params),
	cryptoGetLatestBlock: (params) => cryptoManager.getLatestBlock(params),
	cryptoGetBalance: (params) => cryptoManager.getBalance(params),
};

global.handleMessage = async function (message, callback) {
	console.log('node.js handleMessage ', JSON.stringify(message, null, 2));
	const { messageId, action, data } = message;
	try {
		let result = {};
		const handler = HANDLERS[action];
		console.log('Handler for action', action, ':', typeof handler);
		if (typeof handler === 'function') {
			console.log('Calling handler for', action, 'with data:', data);
			result = await handler(data);
		} else {
			console.log('No handler found for action:', action);
			result = { status: 'error', message: `Unknown action: ${action}` };
		}
		console.log('Handler result for', action, ':', result);
		if (typeof __nativeCallback === 'function') __nativeCallback(messageId, result);
	} catch (error) {
		console.error('Error in handleMessage for action', action, ':', error);
		const errorResult = {
			status: 'error',
			message: error.message,
			stack: error.stack,
		};
		if (typeof __nativeCallback === 'function') __nativeCallback(messageId, errorResult);
	}
};

console.log('JavaScript runtime initialized');
