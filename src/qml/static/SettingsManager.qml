import QtQuick 2.15
import QtQuick.LocalStorage 2.15

QtObject {
	id: root

	property string selectedLanguage: "en"
	property string selectedCurrency: "USD"
	property bool autoTimeSync: true
	property string ntpServer: "pool.ntp.org"
	property string timeZone: "UTC"

	signal languageChanged
	signal currencyChanged
	signal settingsLoaded

	Component.onCompleted: {
		loadSettings();
	}

	function getDatabase() {
		return LocalStorage.openDatabaseSync('wallet_settings', '1', 'Wallet settings', 1000000);
	}

	function loadSettings() {
		var db = getDatabase();
		db.transaction(function (tx) {
			// Create settings table if it doesn't exist
			tx.executeSql('CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY, value TEXT)');

			// Load language setting
			var result = tx.executeSql('SELECT value FROM settings WHERE key = ?', ['language']);
			if (result.rows.length > 0) {
				selectedLanguage = result.rows.item(0).value;
				console.log("Loaded language from storage:", selectedLanguage);
			} else {
				console.log("No language setting found, using default:", selectedLanguage);
			}

			// Load currency setting
			result = tx.executeSql('SELECT value FROM settings WHERE key = ?', ['currency']);
			if (result.rows.length > 0) {
				selectedCurrency = result.rows.item(0).value;
				console.log("Loaded currency from storage:", selectedCurrency);
			} else {
				console.log("No currency setting found, using default:", selectedCurrency);
			}

			// Load auto time sync setting (default true)
			result = tx.executeSql('SELECT value FROM settings WHERE key = ?', ['auto_time_sync']);

			// Load NTP server
			result = tx.executeSql('SELECT value FROM settings WHERE key = ?', ['ntp_server']);
			if (result.rows.length > 0) {
				ntpServer = result.rows.item(0).value;
				console.log("Loaded ntpServer from storage:", ntpServer);
			} else {
				console.log("No ntpServer setting found, using default:", ntpServer);
			}

			// Load Time Zone
			result = tx.executeSql('SELECT value FROM settings WHERE key = ?', ['time_zone']);
			if (result.rows.length > 0) {
				timeZone = result.rows.item(0).value;
				console.log("Loaded timeZone from storage:", timeZone);
			} else {
				console.log("No timeZone setting found, using default:", timeZone);
			}
			if (result.rows.length > 0) {
				var raw = result.rows.item(0).value;
				autoTimeSync = (raw === '1' || raw === 'true' || raw === 1 || raw === true);
				console.log("Loaded autoTimeSync from storage:", autoTimeSync);
			} else {
				console.log("No autoTimeSync setting found, using default:", autoTimeSync);
			}
		});
		// Signal that settings have been loaded
		settingsLoaded();
	}

	function saveLanguage(language) {
		var db = getDatabase();
		db.transaction(function (tx) {
			tx.executeSql('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', ['language', language]);
			console.log("Language saved to storage:", language);
		});
		selectedLanguage = language;
		languageChanged();
	}

	function saveCurrency(currency) {
		var db = getDatabase();
		db.transaction(function (tx) {
			tx.executeSql('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', ['currency', currency]);
			console.log("Currency saved to storage:", currency);
		});
		selectedCurrency = currency;
		currencyChanged();
	}

	function saveAutoTimeSync(enabled) {
		var db = getDatabase();
		db.transaction(function (tx) {
			tx.executeSql('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', ['auto_time_sync', enabled ? '1' : '0']);
			console.log("autoTimeSync saved to storage:", enabled);
		});
		autoTimeSync = !!enabled;
	}

	function saveNtpServer(server) {
		var db = getDatabase();
		db.transaction(function (tx) {
			tx.executeSql('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', ['ntp_server', server]);
			console.log("ntpServer saved to storage:", server);
		});
		ntpServer = server;
	}

	function saveTimeZone(tz) {
		var db = getDatabase();
		db.transaction(function (tx) {
			tx.executeSql('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', ['time_zone', tz]);
			console.log("timeZone saved to storage:", tz);
		});
		timeZone = tz;
	}

	function getSetting(key, defaultValue) {
		var value = defaultValue;
		var db = getDatabase();
		db.transaction(function (tx) {
			var result = tx.executeSql('SELECT value FROM settings WHERE key = ?', [key]);
			if (result.rows.length > 0) {
				value = result.rows.item(0).value;
			}
		});
		return value;
	}

	function setSetting(key, value) {
		var db = getDatabase();
		db.transaction(function (tx) {
			tx.executeSql('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', [key, value]);
		});
	}
}
