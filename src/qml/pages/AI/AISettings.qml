import QtQuick 6.8
import QtQuick.LocalStorage 6.8
import "../../components"

BaseMenu {
	id: root
	property string title: tr('ai.settings.title')
	property string apiKey: ''
	property bool hasError: false
	property string errorMessage: ''

	Component.onCompleted: {
		loadSettings();
	}

	onVisibleChanged: {
		if (visible) {
			loadSettings();
		}
	}

	function loadSettings() {
		console.log('Loading AI settings...');
		try {
			var db = LocalStorage.openDatabaseSync('WalletDB', '1.0', 'Wallet Database', 1000000);
			var settings = null;
			db.transaction(function (tx) {
				tx.executeSql('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
				var result = tx.executeSql('SELECT value FROM settings WHERE key = ?', ['ai_settings']);
				if (result.rows.length > 0) {
					settings = JSON.parse(result.rows.item(0).value);
					console.log('AI settings loaded from database, API key length:', settings.apiKey ? settings.apiKey.length : 0);
				} else
					console.log('No AI settings found in database');
			});

			if (settings && settings.apiKey) {
				apiKey = settings.apiKey;
				apiKeyInput.setText(settings.apiKey);
				console.log('API key loaded into input field');
			} else {
				apiKey = '';
				apiKeyInput.setText('');
				console.log('No API key found, clearing input field');
			}
		} catch (error) {
			console.error('Error loading AI settings:', error);
			apiKey = '';
			apiKeyInput.text = '';
		}
	}

	function saveSettings() {
		console.log('Saving AI settings...');
		console.log('apiKeyInput exists:', typeof apiKeyInput !== 'undefined');
		console.log('Input text value:', apiKeyInput.text);
		console.log('Input getText() value:', apiKeyInput.getText());
		console.log('Input text length:', apiKeyInput.text ? apiKeyInput.text.length : 'undefined');
		console.log('Input getText() length:', apiKeyInput.getText() ? apiKeyInput.getText().length : 'undefined');
		var inputText = apiKeyInput.getText() || '';
		console.log('Processed input text:', inputText);
		console.log('Processed input text length:', inputText.length);
		var settings = {
			apiKey: inputText
		};
		console.log('Settings object:', JSON.stringify(settings));
		try {
			var db = LocalStorage.openDatabaseSync('WalletDB', '1.0', 'Wallet Database', 1000000);
			db.transaction(function (tx) {
				tx.executeSql('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
				tx.executeSql('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', ['ai_settings', JSON.stringify(settings)]);
			});
			apiKey = inputText;
			console.log('AI settings saved successfully, API key length:', inputText.length);
		} catch (error) {
			console.error('Error saving AI settings:', error);
		}
	}

	Column {
		anchors.fill: parent
		anchors.margins: 20
		spacing: 20

		Text {
			text: tr('ai.settings.apikey')
			color: colors.text
			font.pixelSize: 16
		}

		Input {
			id: apiKeyInput
			width: parent.width
			inputPlaceholder: 'sk-...'
			text: apiKey
			inputEchoMode: TextInput.Normal
		}

		MenuButton {
			text: tr('common.save')
			onClicked: saveSettings()
		}

		Alert {
			visible: hasError
			type: 'error'
			message: errorMessage
		}
	}
}
