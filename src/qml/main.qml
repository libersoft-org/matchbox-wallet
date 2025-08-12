import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import "static"
import "components"
import "pages"
import "pages/Settings"
import "utils/NodeUtils.js" as Node

ApplicationWindow {
	id: window
	width: 480
	height: 640
	visible: true
	title: tr("menu.title")
	font.family: "Droid Sans"
	property string iconSource: Qt.resolvedUrl("../img/wallet.svg")
	readonly property int animationDuration: 500
	readonly property var animationEasing: Easing.OutCubic

	// WiFi state for status bar
	property int currentWifiStrength: 0

	// Global signals for WiFi state changes
	signal wifiConnectionChanged
	signal wifiStatusUpdated

	// Function to update WiFi strength
	function updateWifiStrength() {
		Node.msg("wifiGetCurrentStrength", {}, function (response) {
			if (response.status === 'success') {
				currentWifiStrength = response.data.strength || 0;
			} else {
				currentWifiStrength = 0;
			}
		});
	}

	// Timer to periodically update WiFi strength (keep for signal strength only)
	Timer {
		interval: 5000  // Update every 5 seconds
		running: true
		repeat: true
		onTriggered: updateWifiStrength()
	}

	// Create instances of our "singleton" objects
	property var colors: colorsObj
	property var settingsManager: settingsManagerObj
	property var translationManager: translationManagerObj
	property var batteryManager: batteryManagerObj

	// Global properties for timezone navigation
	property var globalTimezones: []
	property string globalSelectedContinent: ""

	Colors {
		id: colorsObj
	}

	SettingsManager {
		id: settingsManagerObj
		onSettingsLoaded: {
			console.log("Settings loaded, setting language to:", selectedLanguage);
			translationManager.setLanguage(selectedLanguage);

			// Use QML Timer instead of setTimeout
			blockTimer.start();

			// Auto-sync time on startup if enabled
			if (SystemManager) {
				if (SystemManager.setNtpServer && settingsManagerObj.ntpServer)
					SystemManager.setNtpServer(settingsManagerObj.ntpServer);
				if (SystemManager.setTimeZone && settingsManagerObj.timeZone)
					SystemManager.setTimeZone(settingsManagerObj.timeZone);
				if (settingsManagerObj.autoTimeSync && SystemManager.syncSystemTime)
					SystemManager.syncSystemTime();
			}
		}
	}

	TranslationManager {
		id: translationManagerObj
	}

	BatteryManager {
		id: batteryManagerObj
	}

	// Global settings - use SettingsManager instance
	property string selectedCurrency: settingsManager.selectedCurrency
	property string selectedLanguage: settingsManager.selectedLanguage

	// Track current page/section
	property string currentPageId: "home"

	// SystemManager is now available as global context property
	// No need to create instance - it's injected from C++

	// Global translation function - available to all child components
	function tr(key) {
		try {
			if (translationManager && translationManager.tr)
				return translationManager.tr(key);
		} catch (e) {
			console.log("Translation error:", e);
		}
		// Fallback - return key
		return key;
	}

	background: Rectangle {
		color: colors.primaryBackground
	}

	Component.onCompleted: {
		x = (Screen.width - width) / 2;
		y = (Screen.height - height) / 2;
		console.log("ApplicationWindow completed");
		// Initialize WiFi strength
		updateWifiStrength();
		// Language initialization is now handled by settingsManager.onSettingsLoaded
	}

	function goPage(component, pageId) {
		if (stackView && component) {
			stackView.push(component);
			if (pageId) {
				window.currentPageId = pageId;
			}
		}
	}

	function goBack() {
		stackView.pop();
		// Update currentPageId based on what's now on top
		if (stackView.currentItem && stackView.currentItem.pageId) {
			window.currentPageId = stackView.currentItem.pageId;
		} else {
			window.currentPageId = "home";
		}
	}

	function goBackMultiple(count) {
		for (var i = 0; i < count; i++) {
			if (stackView.depth > 1) {
				stackView.pop();
			}
		}
		// Update currentPageId based on what's now on top
		if (stackView.currentItem && stackView.currentItem.pageId) {
			window.currentPageId = stackView.currentItem.pageId;
		} else {
			window.currentPageId = "home";
		}
	}

	// Status bar at the very top
	StatusBar {
		id: statusBar

		// Real system values
		wifiStrength: window.currentWifiStrength
		batteryLevel: batteryManager.batteryLevel
		hasBattery: batteryManager.hasBattery

		// Mock values for LoRa and GSM (not implemented yet)
		loraStrength: 0
		gsmStrength: 0  // 0 means no signal/not available
	}

	// Fixed navigation bar below status bar
	Navbar {
		id: fixedNavbar
		anchors.top: statusBar.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		height: window.height * 0.1
		title: stackView.currentItem ? stackView.currentItem.title || "" : ""
		showBackButton: stackView.currentItem && stackView.currentItem.hasOwnProperty("showBackButton") ? stackView.currentItem.showBackButton : true
		showPowerButton: stackView.currentItem && stackView.currentItem.hasOwnProperty("showPowerButton") ? stackView.currentItem.showPowerButton : true
		onBackRequested: window.goBack()
		onPowerOffRequested: window.goPage(powerOffPageComponent)
	}

	// Content area with animations - this part animates
	StackView {
		id: stackView
		anchors.top: fixedNavbar.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		initialItem: mainMenuComponent
		pushEnter: Transition {
			PropertyAnimation {
				property: "x"
				from: stackView.width
				to: 0
				duration: window.animationDuration
				easing.type: window.animationEasing
			}
		}
		pushExit: Transition {
			PropertyAnimation {
				property: "x"
				from: 0
				to: -stackView.width
				duration: window.animationDuration
				easing.type: window.animationEasing
			}
		}
		popEnter: Transition {
			PropertyAnimation {
				property: "x"
				from: -stackView.width
				to: 0
				duration: window.animationDuration
				easing.type: window.animationEasing
			}
		}
		popExit: Transition {
			PropertyAnimation {
				property: "x"
				from: 0
				to: stackView.width
				duration: window.animationDuration
				easing.type: window.animationEasing
			}
		}
	}

	Component {
		id: mainMenuComponent
		MainMenu {
			walletComponent: walletPageComponent
			settingsComponent: settingsPageComponent
			cameraPreviewComponent: cameraPreviewPageComponent
			goPageFunction: window.goPage
		}
	}

	Component {
		id: walletPageComponent
		Wallet {
			goPageFunction: window.goPage
		}
	}

	Component {
		id: settingsPageComponent
		Settings {
			onGeneralSettingsRequested: window.goPage(generalSettingsPageComponent)
			onSystemSettingsRequested: window.goPage(systemSettingsPageComponent)
		}
	}

	// General settings page
	Component {
		id: generalSettingsPageComponent
		SettingsGeneral {
			selectedCurrency: window.selectedCurrency
			onCurrencySelectionRequested: window.goPage(settingsGeneralFiatPageComponent)
		}
	}

	// Currency selection page
	Component {
		id: settingsGeneralFiatPageComponent
		SettingsGeneralFiat {
			onCurrencySelected: function (currency) {
				window.settingsManager.saveCurrency(currency);
				window.goBack();
			}
		}
	}

	// System settings page
	Component {
		id: systemSettingsPageComponent
		SettingsSystem {
			selectedLanguage: window.selectedLanguage
			onWifiSettingsRequested: window.goPage(wifiSettingsPageComponent, "wifi-settings")
			onLanguageSelectionRequested: window.goPage(settingsSystemLanguagePageComponent)
			onTimeSettingsRequested: window.goPage(settingsSystemTimePageComponent)
			onSoundSettingsRequested: window.goPage(settingsSystemSoundPageComponent)
			onDisplaySettingsRequested: window.goPage(settingsSystemDisplayPageComponent)
		}
	}

	// WiFi settings page
	Component {
		id: wifiSettingsPageComponent
		SettingsSystemWiFi {
			onWifiListRequested: window.goPage(wifiListPageComponent)
			onWifiDisconnected: {
				Node.msg("wifiDisconnect", {}, function (response) {
					if (response.status === 'success') {
						console.log("WiFi disconnected successfully");
						window.wifiConnectionChanged();
						window.wifiStatusUpdated();
					} else {
						console.log("Failed to disconnect WiFi:", response.message);
					}
				});
			}
		}
	}

	// WiFi list page
	Component {
		id: wifiListPageComponent
		SettingsSystemWiFiList {
			onPasswordPageRequested: function (networkName, isSecured) {
				console.log("Password page requested for network:", networkName, "secured:", isSecured);
				var passwordPage = wifiPasswordPageComponent.createObject(null, {
					"networkName": networkName,
					"isSecured": isSecured
				});
				stackView.push(passwordPage);
			}
		}
	}

	// WiFi password page
	Component {
		id: wifiPasswordPageComponent
		SettingsSystemWiFiListPassword {}
	}

	// System language selection page
	Component {
		id: settingsSystemLanguagePageComponent
		SettingsSystemLanguage {
			onLanguageSelected: function (languageCode) {
				window.settingsManager.saveLanguage(languageCode);
				window.translationManager.setLanguage(languageCode);
				window.goBack();
			}
		}
	}

	// System time settings page
	Component {
		id: settingsSystemTimePageComponent
		SettingsSystemTime {
			onTimeChanged: function (timeString) {
				console.log("Time changed to:", timeString);
				// TODO: Implement actual system time setting
				window.goBack();
			}
			onTimezoneSettingsRequested: window.goPage(settingsSystemTimeZonesPageComponent)
		}
	}

	// System sound settings page
	Component {
		id: settingsSystemSoundPageComponent
		SettingsSystemSound {
			onVolumeChanged: function (volume) {
				console.log("Volume changed to:", volume);
				// TODO: Implement actual system volume setting
			}
		}
	}

	// System display settings page
	Component {
		id: settingsSystemDisplayPageComponent
		SettingsSystemDisplay {
			onBrightnessChanged: function (brightness) {
				console.log("Brightness changed to:", brightness);
				// TODO: Implement actual system brightness setting
			}
		}
	}

	// System timezone selection page (continents)
	Component {
		id: settingsSystemTimeZonesPageComponent
		SettingsSystemTimeZones {
			onTimezoneSelected: function (tz) {
				if (window.settingsManager)
					window.settingsManager.saveTimeZone(tz);

				// Change system timezone using NodeUtils
				Node.msg("systemChangeTimeZone", {
					timezone: tz
				}, function (response) {
					console.log("Timezone change response:", JSON.stringify(response));
					if (response.status === 'success') {
						console.log("Timezone successfully changed to:", tz);
					} else {
						console.error("Failed to change timezone:", response.message || "Unknown error");
					}
				});

				window.goBack();
			}
			onContinentSelected: function (continent) {
				// Store timezones globally and navigate to cities
				window.globalTimezones = timezones;
				window.globalSelectedContinent = continent;
				window.goPage(settingsSystemTimeZonesCitiesPageComponent);
			}
		}
	}

	// System timezone cities selection page
	Component {
		id: settingsSystemTimeZonesCitiesPageComponent
		SettingsSystemTimeZones {
			selectedContinent: window.globalSelectedContinent
			timezones: window.globalTimezones || []
			onTimezoneSelected: function (tz) {
				if (window.settingsManager)
					window.settingsManager.saveTimeZone(tz);

				// Change system timezone using NodeUtils
				Node.msg("systemChangeTimeZone", {
					timezone: tz
				}, function (response) {
					console.log("Timezone change response:", JSON.stringify(response));
					if (response.status === 'success') {
						console.log("Timezone successfully changed to:", tz);
					} else {
						console.error("Failed to change timezone:", response.message || "Unknown error");
					}
				});

				// Clear global state
				window.globalSelectedContinent = "";
				window.globalTimezones = [];
				// Go back 2 levels to return to SettingsSystemTime
				window.goBackMultiple(2);
			}
		}
	}

	// Power off page
	Component {
		id: powerOffPageComponent
		PowerOff {}
	}

	// Camera preview page
	Component {
		id: cameraPreviewPageComponent
		CameraPreview {}
	}
}
