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

 Component.onCompleted: {
  x = (Screen.width - width) / 2;
  y = (Screen.height - height) / 2;
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
  }
 }

 Component {
  id: settingsPageComponent
  Settings {
   onBackRequested: {
   	stackView.pop();
   }
   onSystemSettingsRequested: {
	   stackView.push(systemSettingsPageComponent);
   }
  }
 }

 // System settings page component
 Component {
  id: systemSettingsPageComponent
  SettingsSystem {
   onBackRequested: {
	stackView.pop();
   }
   onWifiSettingsRequested: {
	stackView.push(wifiSettingsPageComponent);
   }
  }
 }

 // WiFi settings page component
 Component {
  id: wifiSettingsPageComponent
  SettingsSystemWiFi {
   onBackRequested: {
	stackView.pop();
   }
  }
 }

 // Power off page component
 Component {
  id: powerOffPageComponent
  PowerOff {
   onBackRequested: {
    stackView.pop();
   }
  }
 }

 // Camera preview page component
 Component {
  id: cameraPreviewPageComponent
  CameraPreview {
   onBackRequested: {
	stackView.pop();
   }
  }
 }
}
