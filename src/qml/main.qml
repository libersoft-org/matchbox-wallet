import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
 id: window
 width: 800
 height: 600
 visible: true
 title: qsTr("Main Menu App")

 // Center the window on screen
 Component.onCompleted: {
  x = (Screen.width - width) / 2;
  y = (Screen.height - height) / 2;
 }

 // Stack view for navigation
 StackView {
  id: stackView
  anchors.fill: parent
  initialItem: mainMenuComponent
 }

 // Main menu component
 Component {
  id: mainMenuComponent
  MainMenu {
   onPowerOffRequested: {
	Qt.quit();
   }
   onSettingsRequested: {
	stackView.push(settingsPageComponent);
   }
  }
 }

 // Settings page component
 Component {
  id: settingsPageComponent
  SettingsPage {
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
  SystemSettingsPage {
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
  WiFiSettingsPage {
   onBackRequested: {
	stackView.pop();
   }
  }
 }
}
