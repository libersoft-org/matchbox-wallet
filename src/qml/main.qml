import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import WalletModule 1.0
import "components"
import "pages"
import "pages/Settings"

ApplicationWindow {
 id: window
 width: 480
 height: 640
 visible: true
 title: tr("menu.title")
 font.family: "Droid Sans"
 property string iconSource: "qrc:/WalletModule/src/img/wallet.svg"
 readonly property int animationDuration: 500
 readonly property var animationEasing: Easing.OutCubic

 // Load singletons
 Loader {
  id: colorsLoader
  source: "singletons/Colors.qml"
 }
 
 Loader {
  id: settingsManagerLoader
  source: "singletons/SettingsManager.qml"
  onLoaded: checkInitialization()
 }
 
 Loader {
  id: translationManagerLoader
  source: "singletons/TranslationManager.qml"
  onLoaded: {
   console.log("TranslationManager loaded");
   // Connect to languageChanged signal to update UI when translations are loaded
   if (item) {
    item.languageChanged.connect(function() {
     console.log("Language changed signal received");
     forceUIUpdate();
    });
   }
   checkInitialization();
  }
 }

 // Track initialization state
 property bool isInitialized: false
 
 function checkInitialization() {
  if (settingsManagerLoader.item && translationManagerLoader.item && !isInitialized) {
   isInitialized = true;
   console.log("All singletons loaded, initializing...");
   // Initialize TranslationManager with saved language
   translationManagerLoader.item.setLanguage(settingsManagerLoader.item.selectedLanguage);
  }
 }
 
 function forceUIUpdate() {
  // Force UI update by incrementing a dummy property
  uiUpdateCounter++;
 }
 
 property int uiUpdateCounter: 0

 // Global aliases for easier access - use lowercase for QML compliance
 property alias colors: colorsLoader.item
 property alias settingsManager: settingsManagerLoader.item
 property alias translationManager: translationManagerLoader.item

 // Global settings - use SettingsManager
 property string selectedCurrency: settingsManager ? settingsManager.selectedCurrency : "USD"
 property string selectedLanguage: settingsManager ? settingsManager.selectedLanguage : "en"

 // System manager for real-time system data
 SystemManager {
  id: systemManager
 }

 // Global translation function - available to all child components
 function tr(key) {
  // Force binding update when translations change
  var dummy = uiUpdateCounter;
  
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
  color: colors ? colors.primaryBackground : "#222"
 }

 Component.onCompleted: {
  x = (Screen.width - width) / 2;
  y = (Screen.height - height) / 2;
  
  console.log("ApplicationWindow completed");
 }

 function goPage(component) {
  if (stackView && component)
   stackView.push(component);
 }

 function goBack() {
  stackView.pop();
 }

 // Status bar at the very top
 StatusBar {
  id: statusBar
  anchors.top: parent.top
  anchors.left: parent.left
  anchors.right: parent.right
  height: window.height * 0.1

  // Real system values
  wifiStrength: systemManager.currentWifiStrength
  batteryLevel: systemManager.batteryLevel
  hasBattery: systemManager.hasBattery

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
	settingsManager.saveCurrency(currency);
	window.goBack();
   }
  }
 }

 // System settings page
 Component {
  id: systemSettingsPageComponent
  SettingsSystem {
   selectedLanguage: window.selectedLanguage
   onWifiSettingsRequested: window.goPage(wifiSettingsPageComponent)
   onLanguageSelectionRequested: window.goPage(settingsSystemLanguagePageComponent)
   onTimeSettingsRequested: window.goPage(settingsSystemTimePageComponent)
  }
 }

 // WiFi settings page
 Component {
  id: wifiSettingsPageComponent
  SettingsSystemWiFi {
   onWifiListRequested: window.goPage(wifiListPageComponent)
  }
 }

 // WiFi list page
 Component {
  id: wifiListPageComponent
  SettingsSystemWiFiList {
  }
 }

 // System language selection page
 Component {
  id: settingsSystemLanguagePageComponent
  SettingsSystemLanguage {
   onLanguageSelected: function (languageCode) {
	settingsManager.saveLanguage(languageCode);
	translationManager.setLanguage(languageCode);
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
  }
 }

 // Power off page
 Component {
  id: powerOffPageComponent
  PowerOff {
  }
 }

 // Camera preview page
 Component {
  id: cameraPreviewPageComponent
  CameraPreview {
  }
 }
}
