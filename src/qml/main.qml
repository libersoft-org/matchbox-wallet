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
 title: qsTr("Matchbox Wallet")
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

 // Animation constants
 readonly property int animationDuration: 500
 readonly property var animationEasing: Easing.OutCubic

 StackView {
  id: stackView
  anchors.fill: parent
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
   onPowerOffRequested: window.goPage(powerOffPageComponent)
   onSystemSettingsRequested: window.goPage(systemSettingsPageComponent);
   onGeneralSettingsRequested: window.goPage(generalSettingsPageComponent);
  }
 }

 // General settings page
 Component {
  id: generalSettingsPageComponent
  SettingsGeneral {
   onBackRequested: window.goBack()
   onPowerOffRequested: window.goPage(powerOffPageComponent)
   onCurrencySelectionRequested: window.goPage(settingsGeneralFiatPageComponent);
  }
 }

 // Currency selection page
 Component {
  id: settingsGeneralFiatPageComponent
  SettingsGeneralFiat {
   onBackRequested: window.goBack()
   onPowerOffRequested: window.goPage(powerOffPageComponent)
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
   onPowerOffRequested: window.goPage(powerOffPageComponent)
   onWifiSettingsRequested: window.goPage(wifiSettingsPageComponent);
  }
 }

 // WiFi settings page
 Component {
  id: wifiSettingsPageComponent
  SettingsSystemWiFi {
   onBackRequested: window.goBack()
   onPowerOffRequested: window.goPage(powerOffPageComponent)
  }
 }

 // Power off page
 Component {
  id: powerOffPageComponent
  PowerOff {
   onBackRequested: window.goBack()
  }
 }

 // Camera preview page
 Component {
  id: cameraPreviewPageComponent
  CameraPreview {
   onBackRequested: window.goBack()
   onPowerOffRequested: window.goPage(powerOffPageComponent)
  }
 }
}
