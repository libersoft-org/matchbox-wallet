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
 title: qsTr("Yellow Matchbox Wallet")
 font.family: AppConstants.fontFamily
 
 background: Rectangle {
  color: AppConstants.primaryBackground
 }

 Component.onCompleted: {
  x = (Screen.width - width) / 2;
  y = (Screen.height - height) / 2;
 }

 function goPage(component) {
		if (stackView && component) stackView.push(component);
	}

 function goBack() {
  stackView.pop();
 }

 StackView {
  id: stackView
  anchors.fill: parent
  initialItem: mainMenuComponent
 }

 Component {
  id: mainMenuComponent
  MainMenu {
   settingsComponent: settingsPageComponent
   powerOffComponent: powerOffPageComponent
   cameraPreviewComponent: cameraPreviewPageComponent
   goPageFunction: window.goPage
  }
 }

 Component {
  id: settingsPageComponent
  Settings {
   onBackRequested: window.goBack()
   onSystemSettingsRequested: window.goPage(systemSettingsPageComponent);
   onGeneralSettingsRequested: window.goPage(generalSettingsPageComponent);
  }
 }

 // General settings page
 Component {
  id: generalSettingsPageComponent
  SettingsGeneral {
   onBackRequested: window.goBack()
   onCurrencySelectionRequested: window.goPage(settingsGeneralFiatPageComponent);
  }
 }

 // Currency selection page
 Component {
  id: settingsGeneralFiatPageComponent
  SettingsGeneralFiat {
   onBackRequested: window.goBack()
   onCurrencySelected: function(currency) {
    // TODO: Update selected currency in SettingsGeneral
    console.log("Currency selected:", currency);
    window.goBack();
   }
  }
 }

 // System settings page
 Component {
  id: systemSettingsPageComponent
  SettingsSystem {
   onBackRequested: window.goBack()
   onWifiSettingsRequested: window.goPage(wifiSettingsPageComponent);
  }
 }

 // WiFi settings page
 Component {
  id: wifiSettingsPageComponent
  SettingsSystemWiFi {
   onBackRequested: window.goBack()
  }
 }

 // Power off page
 Component {
  id: powerOffPageComponent
  PowerOff {
   goBackFunction: window.goBack
  }
 }

 // Camera preview page
 Component {
  id: cameraPreviewPageComponent
  CameraPreview {
   onBackRequested: window.goBack()
  }
 }
}
