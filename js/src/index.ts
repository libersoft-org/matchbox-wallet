import * as crypto2 from 'libersoft-crypto';
import { crypto2getAddressBookItems } from './crypto2_helper';
import { popEvents } from './EventQueue';

// @ts-ignore
import WifiManager from './wifi.js';
// @ts-ignore
import BatteryManager from './battery.js';
// @ts-ignore
import PowerManager from './power.js';
// @ts-ignore
import TimeManager from './time.js';
// @ts-ignore
import AudioManager from './audio.js';
// @ts-ignore
import DisplayManager from './display.js';
// @ts-ignore
import TestManager from './test.js';
// @ts-ignore
import SystemManager from './system.js';
// @ts-ignore
import FirewallManager from './firewall.js';
// @ts-ignore
import CryptoManager from './crypto0.js';
// @ts-ignore
import SpeedTestManager from './speedtest.js';

interface Message {
	messageId: string;
	action: string;
	data?: any;
}

interface ErrorResult {
	status: 'error';
	message: string;
	stack?: string;
}

declare global {
	var handleMessage: (message: Message, callback?: any) => Promise<void>;
	var __nativeCallback: (messageId: string, result: any) => void;
	var __nativeRequire: (module: string) => any;
	var NodeJS: any;
	var applicationName: any;
	var applicationVersion: any;
	var wifiStrengthUpdateInterval: any;
	var batteryStatusUpdateInterval: any;
	var eventsPollInterval: any;
}
const wifiManager = new WifiManager();
const batteryManager = new BatteryManager();
const powerManager = new PowerManager();
const timeManager = new TimeManager();
const audioManager = new AudioManager();
const displayManager = new DisplayManager();
const testManager = new TestManager();
const systemManager = new SystemManager();
const firewallManager = new FirewallManager();
const cryptoManager = new CryptoManager();
const speedTestManager = new SpeedTestManager();

const HANDLERS: { [key: string]: (params?: any) => any } = {
	popEvents: () => popEvents(),

	testPing: () => testManager.ping(),
	testDelayedPing: (params) => testManager.delayedPing(params),
	batteryGetInfo: () => batteryManager.getBatteryInfo(),
	batteryCheckStatus: () => batteryManager.checkBatteryStatus(),
	powerReboot: () => powerManager.reboot(),
	powerShutdown: () => powerManager.shutdown(),
	timeListTimeZones: () => timeManager.listTimeZones(),
	timeGetCurrentTimezone: () => timeManager.getCurrentTimezone(),
	timeChangeTimeZone: (params) => timeManager.changeTimeZone(params),
	timeSetAutoTimeSync: (params) => timeManager.setAutoTimeSync(params),
	timeGetAutoTimeSyncStatus: () => timeManager.getAutoTimeSyncStatus(),
	timeSetSystemDateTime: (params) => timeManager.setSystemDateTime(params),
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
	firewallGetStatus: () => firewallManager.getFirewallStatus(),
	firewallSetEnabled: (params) => firewallManager.setFirewallEnabled(params.enabled),
	firewallSetExceptionEnabled: (params) => firewallManager.setExceptionEnabled(params.port, params.protocol, params.enabled, params.description),
	firewallAddException: (params) => firewallManager.addException(params.port, params.protocol, params.description),
	firewallRemoveException: (params) => firewallManager.removeException(params.port, params.protocol),
	firewallResetToDefaults: () => firewallManager.resetToDefaults(),

	crypto2addAddressBookItem: (params) => crypto2.addAddressBookItem(params.name, params.address),
	crypto2editAddressBookItem: (params) => crypto2.editAddressBookItem(params.itemGuid, params.name, params.address),
	crypto2deleteAddressBookItem: (params) => crypto2.deleteAddressBookItem(params.itemGuid),
	crypto2findAddressBookItemByAddress: (params) => crypto2.findAddressBookItemByAddress(params.address),
	crypto2findAddressBookItemByID: (params) => crypto2.findAddressBookItemByID(params.guid),
	crypto2hasAddressBookItems: () => crypto2.hasAddressBookItems(),
	crypto2getAddressBookItems: () => crypto2getAddressBookItems(),
	crypto2validateAddressBookItem: (params) => crypto2.validateAddressBookItem(params.name, params.address, params.excludeItemGuid),
	crypto2importAddressBookItems: (params) => crypto2.importAddressBookItems(params.text),
	crypto2replaceAddressBook: (params) => crypto2.replaceAddressBook(params.text),
	crypto2reorderAddressBook: (params) => crypto2.reorderAddressBook(params.reorderedItems),
	crypto2validateAddressBookImport: (params) => crypto2.validateAddressBookImport(params.text),

	// crypto0.js handlers
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
	speedPing: (params) => speedTestManager.ping(params),
	speedDownload: (params) => speedTestManager.download(params),
	speedUpload: (params) => speedTestManager.upload(params),
};

(global as any).handleMessage = async function (message: Message, callback?: any): Promise<void> {
	//console.log('node.js handleMessage ', JSON.stringify(message, null, 2));
	const { messageId, action, data } = message;
	try {
		let result: any = {};
		const handler = HANDLERS[action];
		//console.log('Handler for action', action, ':', typeof handler);
		if (typeof handler === 'function') {
			//console.log('Calling handler for', action, 'with data:', data);
			result = await handler(data);
		} else {
			//console.log('No handler found for action:', action);
			result = { status: 'error', message: `Unknown action: ${action}` };
		}
		//console.log('Handler result for', action, ':', result);
		if (typeof (global as any).__nativeCallback === 'function') (global as any).__nativeCallback(messageId, result);
	} catch (error: any) {
		//console.error('Error in handleMessage for action', action, ':', error);
		const errorResult: ErrorResult = {
			status: 'error',
			message: error.message,
			stack: error.stack,
		};
		if (typeof (global as any).__nativeCallback === 'function') (global as any).__nativeCallback(messageId, errorResult);
	}
};

// Export handleMessage to globalThis for native require() compatibility
(globalThis as any).handleMessage = (global as any).handleMessage;

console.log('js/src/index.ts initialized');
