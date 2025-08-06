import QtQuick 2.15
import QtQuick.LocalStorage 2.15

QtObject {
 id: root

 property string selectedLanguage: "en"
 property string selectedCurrency: "USD"

 signal languageChanged
 signal currencyChanged

 Component.onCompleted: {
  loadSettings();
 }

 function loadSettings() {
  var db = LocalStorage.openDatabaseSync("MatchboxWallet", "1.0", "Matchbox Wallet Settings", 1000000);
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
   });
 }

 function saveLanguage(language) {
  var db = LocalStorage.openDatabaseSync("MatchboxWallet", "1.0", "Matchbox Wallet Settings", 1000000);
  db.transaction(function (tx) {
	tx.executeSql('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', ['language', language]);
	console.log("Language saved to storage:", language);
   });
  selectedLanguage = language;
  languageChanged();
 }

 function saveCurrency(currency) {
  var db = LocalStorage.openDatabaseSync("MatchboxWallet", "1.0", "Matchbox Wallet Settings", 1000000);
  db.transaction(function (tx) {
	tx.executeSql('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', ['currency', currency]);
	console.log("Currency saved to storage:", currency);
   });
  selectedCurrency = currency;
  currencyChanged();
 }

 function getSetting(key, defaultValue) {
  var value = defaultValue;
  var db = LocalStorage.openDatabaseSync("MatchboxWallet", "1.0", "Matchbox Wallet Settings", 1000000);
  db.transaction(function (tx) {
	var result = tx.executeSql('SELECT value FROM settings WHERE key = ?', [key]);
	if (result.rows.length > 0) {
	 value = result.rows.item(0).value;
	}
   });
  return value;
 }

 function setSetting(key, value) {
  var db = LocalStorage.openDatabaseSync("MatchboxWallet", "1.0", "Matchbox Wallet Settings", 1000000);
  db.transaction(function (tx) {
	tx.executeSql('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', [key, value]);
   });
 }
}
