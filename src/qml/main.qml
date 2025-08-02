import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import WalletModule 1.0
import "components"
import "pages"

ApplicationWindow {
 id: window
 width: 480
 height: 640
 visible: true
 title: qsTr("Yellow Matchbox Wallet")
 
 // Set global font for the entire application
 font.family: AppConstants.fontFamily

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
	stackView.push(powerOffPageComponent);
   }
   onSettingsRequested: {
	stackView.push(settingsPageComponent);
   }
   onCameraPreviewRequested: {
	stackView.push(cameraPreviewPageComponent);
   }
  }
 }

 // Settings page component
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
   onExitRequested: {
	Qt.quit();
   }
   onRebootRequested: {
	console.log("Reboot system requested - would execute system reboot command");
	// In real implementation: QProcess.startDetached("reboot");
   }
   onShutdownRequested: {
	console.log("Shutdown system requested - would execute system shutdown command");
	// In real implementation: QProcess.startDetached("shutdown", ["-h", "now"]);
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
