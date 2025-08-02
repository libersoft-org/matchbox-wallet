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
 property string iconSource: "qrc:/WalletModule/src/img/wallet.svg"
 readonly property int animationDuration: 500
 readonly property var animationEasing: Easing.OutCubic
 
 // Global currency setting
 property string selectedCurrency: "USD"
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

 // Fixed navigation bar at top
 NavigationBar {
  id: fixedNavigationBar
  anchors.top: parent.top
  anchors.left: parent.left
  anchors.right: parent.right
  height: window.height * 0.1
  title: stackView.currentItem ? stackView.currentItem.title || "" : ""
  showBackButton: stackView.currentItem.showBackButton
  showPowerButton: stackView.currentItem.showPowerButton
  onBackRequested: window.goBack()
  onPowerOffRequested: window.goPage(powerOffPageComponent)
 }

 // Content area with animations - this part animates
 StackView {
  id: stackView
  anchors.top: fixedNavigationBar.bottom
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
   settingsComponent: settingsPageComponent
   cameraPreviewComponent: cameraPreviewPageComponent
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
   onCurrencySelected: function(currency) {
    window.selectedCurrency = currency;
    window.goBack();
   }
  }
 }

 // System settings page
 Component {
  id: systemSettingsPageComponent
  SettingsSystem {
   onWifiSettingsRequested: window.goPage(wifiSettingsPageComponent)
  }
 }

 // WiFi settings page
 Component {
  id: wifiSettingsPageComponent
  SettingsSystemWiFi {
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
   // Stop camera before going back - this will be handled by NavigationBar
  }
 }
}
