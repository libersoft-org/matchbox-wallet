import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.VirtualKeyboard 2.15
import QtMultimedia 6.0
import "static"
import "components"
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
	property bool showSplashScreen: true
	property var colors: colors
	property var settingsManager: settingsManagerObj
	property var translationManager: translationManagerObj
	property var batteryManager: batteryManagerObj
	property var eventManager: eventManagerObj
	property var globalTimezones: []
	property string globalSelectedPath: ""
	property int timezoneNavigationDepth: 0
	property string selectedCurrency: settingsManager.selectedCurrency
	property string selectedLanguage: settingsManager.selectedLanguage
	property string currentPageId: "home"
	property bool isFullscreen: false
	signal wifiConnectionChanged
	signal wifiStatusUpdated

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

	function goPage(componentName, pageId, properties) {
		if (stackView) {
			var fullPath = componentName.startsWith('pages/') ? componentName : 'pages/' + componentName;
			var component = Qt.createComponent(fullPath);
			if (component.status === Component.Error) {
				console.error("Failed to load component:", fullPath, "Error:", component.errorString());
				return;
			}
			var componentInstance;
			if (properties)
				componentInstance = component.createObject(null, properties);
			else
				componentInstance = component.createObject(null);
			if (componentInstance) {
				stackView.push(componentInstance);
				if (pageId)
					window.currentPageId = pageId;
			} else
				console.error("Failed to create component instance:", fullPath);
		}
	}

	function goBack() {
		stackView.pop();
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
		if (stackView.currentItem && stackView.currentItem.pageId)
			window.currentPageId = stackView.currentItem.pageId;
		else
			window.currentPageId = "home";
	}

	Colors {
		id: colors
	}

	SettingsManager {
		id: settingsManagerObj
		onSettingsLoaded: {
			console.log("Settings loaded, setting language to:", selectedLanguage);
			translationManager.setLanguage(selectedLanguage);
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

	background: Rectangle {
		color: colors.primaryBackground
	}

	Component.onCompleted: {
		x = (Screen.width - width) / 2;
		y = (Screen.height - height) / 2;
		//console.log("ApplicationWindow completed");
	}

	// Status bar at the very top
	StatusBar {
		id: statusBar
		visible: !window.showSplashScreen && !window.isFullscreen
		batteryLevel: batteryManager.batteryLevel
		hasBattery: batteryManager.hasBattery
		// TODO: Mock values for LoRa and GSM (not implemented yet)
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
		onPowerRequested: window.goPage('Power.qml')
	}

	// Content area with animations
	StackView {
		id: stackView
		visible: !window.showSplashScreen
		anchors.top: window.isFullscreen ? parent.top : fixedNavbar.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		initialItem: Qt.createComponent("pages/MainMenu.qml")
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
}
