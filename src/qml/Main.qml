import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.VirtualKeyboard 2.15
import QtMultimedia 6.0
import "static"
import "components"
import "pages"
import "pages/Settings"
import "pages/Player"
import "pages/Wallet"
import "utils/NodeUtils.js" as Node

ApplicationWindow {
	id: window
	width: 480
	height: 640
	visible: true
	title: applicationName
	font.family: "Droid Sans"
	property string iconSource: Qt.resolvedUrl("../img/wallet.svg")
	readonly property int animationDuration: 500
	readonly property var animationEasing: Easing.OutCubic

	// Splash screen state
	property bool showSplashScreen: true

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
		interval: wifiStrengthUpdateInterval
		running: true
		repeat: true
		onTriggered: updateWifiStrength()
	}

	// Create instances of our "singleton" objects
	property var colors: colors
	property var settingsManager: settingsManagerObj
	property var translationManager: translationManagerObj
	property var batteryManager: batteryManagerObj
	property var eventManager: eventManagerObj

	// Global properties for timezone navigation
	property var globalTimezones: []
	property string globalSelectedPath: ""
	property int timezoneNavigationDepth: 0

	Colors {
		id: colors
	}

	SettingsManager {
		id: settingsManagerObj
		onSettingsLoaded: {
			console.log("Settings loaded, setting language to:", selectedLanguage);
			translationManager.setLanguage(selectedLanguage);

			// Auto-sync time on startup if enabled
			// TODO: Implement time sync via Node.js if needed
			// if (SystemManager) {
			//	if (SystemManager.setNtpServer && settingsManagerObj.ntpServer)
			//		SystemManager.setNtpServer(settingsManagerObj.ntpServer);
			//	if (SystemManager.setTimeZone && settingsManagerObj.timeZone)
			//		SystemManager.setTimeZone(settingsManagerObj.timeZone);
			//	if (settingsManagerObj.autoTimeSync && SystemManager.syncSystemTime)
			//		SystemManager.syncSystemTime();
			// }
		}
	}

	TranslationManager {
		id: translationManagerObj
	}

	BatteryManager {
		id: batteryManagerObj
	}

	EventManager {
		id: eventManagerObj
	}

	// Global settings - use SettingsManager instance
	property string selectedCurrency: settingsManager.selectedCurrency
	property string selectedLanguage: settingsManager.selectedLanguage

	// Track current page/section
	property string currentPageId: "home"
	property bool isFullscreen: false

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
		// Language initialization is now handled by settingsManager.onSettingsLoadedgoPage(
	}

	function goPage(component, pageId) {
		if (stackView && component) {
			stackView.push(component);
			if (pageId)
				window.currentPageId = pageId;
		}
	}

	function goBack() {
		stackView.pop();
		// Update currentPageId based on what's now on top
		if (stackView.currentItem && stackView.currentItem.pageId)
			window.currentPageId = stackView.currentItem.pageId;
		else
			window.currentPageId = "home";
	}

	function goBackMultiple(count) {
		for (var i = 0; i < count; i++) {
			if (stackView.depth > 1)
				stackView.pop();
		}
		// Update currentPageId based on what's now on top
		if (stackView.currentItem && stackView.currentItem.pageId)
			window.currentPageId = stackView.currentItem.pageId;
		else
			window.currentPageId = "home";
	}

	// Status bar at the very top
	StatusBar {
		id: statusBar
		visible: !window.showSplashScreen && !window.isFullscreen
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
		visible: !window.showSplashScreen && !window.isFullscreen
		anchors.top: statusBar.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		title: stackView.currentItem ? stackView.currentItem.title || "" : ""
		showBackButton: stackView.currentItem && stackView.currentItem.hasOwnProperty("showBackButton") ? stackView.currentItem.showBackButton : true
		showPowerButton: stackView.currentItem && stackView.currentItem.hasOwnProperty("showPowerButton") ? stackView.currentItem.showPowerButton : true
		onBackRequested: window.goBack()
		onPowerRequested: window.goPage(powerPageComponent)
	}

	// Content area with animations - this part animates
	StackView {
		id: stackView
		visible: !window.showSplashScreen
		anchors.top: window.isFullscreen ? parent.top : fixedNavbar.bottom
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

	SplashScreen {
		id: splashScreen
		anchors.fill: parent
		visible: window.showSplashScreen
		onAnimationFinished: {
			window.showSplashScreen = false;
		}
	}

	// Virtual Keyboard
	InputPanel {
		id: inputPanel
		z: 99
		x: 0
		y: window.height
		width: window.width

		states: State {
			name: "visible"
			when: inputPanel.active
			PropertyChanges {
				inputPanel.y: window.height - inputPanel.height
			}
		}
		transitions: Transition {
			from: ""
			to: "visible"
			reversible: true
			ParallelAnimation {
				NumberAnimation {
					properties: "y"
					duration: 250
					easing.type: Easing.InOutQuad
				}
			}
		}
	}

	Component {
		id: mainMenuComponent
		MainMenu {}
	}

	Component {
		id: walletPageComponent
		Wallet {}
	}

	Component {
		id: walletSettingsPageComponent
		WalletSettings {}
	}

	Component {
		id: walletSettingsGeneralPageComponent
		WalletSettingsGeneral {}
	}

	Component {
		id: settingsPageComponent
		Settings {}
	}

	Component {
		id: walletSettingsGeneralFiatPageComponent
		WalletSettingsGeneralFiat {}
	}

	Component {
		id: settingsWifiPageComponent
		SettingsWiFi {}
	}

	Component {
		id: wifiListPageComponent
		SettingsWiFiList {}
	}

	Component {
		id: wifiPasswordPageComponent
		SettingsWiFiListPassword {}
	}

	Component {
		id: settingsLanguagePageComponent
		SettingsLanguage {}
	}

	Component {
		id: settingsTimePageComponent
		SettingsTime {}
	}

	Component {
		id: settingsSoundPageComponent
		SettingsSound {}
	}

	Component {
		id: settingsFirewallPageComponent
		SettingsFirewall {}
	}

	Component {
		id: firewallExceptionsPageComponent
		SettingsFirewallExceptions {}
	}

	Component {
		id: settingsDisplayPageComponent
		SettingsDisplay {
			onBrightnessChanged: function (brightness) {
				console.log("Brightness changed to:", brightness);
				// TODO: Implement actual system brightness setting
			}
		}
	}

	Component {
		id: settingsTimeZonesPageComponent
		SettingsTimeZones {
			Component.onCompleted: {
				// Reset navigation depth when entering timezone selection
				window.timezoneNavigationDepth = 1;
			}
			onTimezoneSelected: function (tz) {
				// Change system timezone using NodeUtils
				Node.msg("timeChangeTimeZone", {
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
			onPathSelected: function (path) {
				// Store timezones globally and navigate deeper
				window.globalTimezones = timezones;
				window.globalSelectedPath = path;
				window.timezoneNavigationDepth++;
				window.goPage(settingsTimeZonesSubPageComponent);
			}
		}
	}

	Component {
		id: settingsTimeZonesSubPageComponent
		SettingsTimeZones {
			currentPath: window.globalSelectedPath
			timezones: window.globalTimezones || []

			Component.onDestruction: {
				// When going back (not selecting timezone), decrement depth
				if (window.timezoneNavigationDepth > 0) {
					window.timezoneNavigationDepth--;
					console.log("Back navigation, depth now:", window.timezoneNavigationDepth);
				}
			}

			onTimezoneSelected: function (tz) {
				// Change system timezone using NodeUtils
				Node.msg("timeChangeTimeZone", {
					timezone: tz
				}, function (response) {
					console.log("Timezone change response:", JSON.stringify(response));
					if (response.status === 'success') {
						console.log("Timezone successfully changed to:", tz);
					} else {
						console.error("Failed to change timezone:", response.message || "Unknown error");
					}
				});

				// Clear global state and go back the exact number of steps
				var stepsBack = window.timezoneNavigationDepth;
				window.globalSelectedPath = "";
				window.globalTimezones = [];
				window.timezoneNavigationDepth = 0;
				window.goBackMultiple(stepsBack);
			}
			onPathSelected: function (path) {
				// Navigate deeper - create new instance with deeper path
				window.globalSelectedPath = path;
				window.timezoneNavigationDepth++;
				window.goPage(settingsTimeZonesSubPageComponent);
			}
		}
	}

	Component {
		id: settingsUpdatePageComponent
		SettingsUpdate {}
	}

	Component {
		id: powerPageComponent
		Power {}
	}

	Component {
		id: cameraPreviewPageComponent
		CameraPreview {}
	}

	Component {
		id: keyboardTestPageComponent
		KeyboardTest {}
	}

	Component {
		id: mediaPlayerPageComponent
		Player {
			goPageFunction: window.goPage
			playerLocalComponent: playerLocalPageComponent
			playerNetworkComponent: playerNetworkPageComponent
		}
	}

	Component {
		id: playerLocalPageComponent
		PlayerLocal {
			goPageFunction: window.goPage
			playerVideoComponent: playerVideoPageComponent
		}
	}

	Component {
		id: playerNetworkPageComponent
		PlayerNetwork {
			goPageFunction: window.goPage
			playerVideoComponent: playerVideoPageComponent
		}
	}

	Component {
		id: playerVideoPageComponent
		PlayerVideo {
			onFullscreenRequested: function (fullscreen) {
				window.isFullscreen = fullscreen;
			}
		}
	}
}
