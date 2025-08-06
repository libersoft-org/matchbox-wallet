import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

Rectangle {
 id: root
 color: Colors.primaryBackground
 property string title: tr("menu.settings.system.wifi.title")
 signal backRequested
 signal powerOffRequested
 signal wifiListRequested

 // WiFi Manager instance
 WiFiManager {
  id: wifiManager

  onConnectionResult: function (ssid, success, error) {
   if (success)
	console.log("Successfully connected to", ssid);
   else
	console.log("Failed to connect to", ssid, "Error:", error);
  }
 }

 // Scan on component load to get current connection status
 Component.onCompleted: {
  wifiManager.scanNetworks();
 }

 ColumnLayout {
  anchors.fill: parent
  anchors.margins: 30
  spacing: 30

  ColumnLayout {
   anchors.fill: parent
   anchors.margins: 20
   spacing: 15

   Text {
	text: tr("settings.system.wifi.current.status")
	font.pointSize: 14
	font.bold: true
	color: "#333333"
	Layout.alignment: Qt.AlignHCenter
   }

   // WiFi icon
   Text {
	text: "📶"
	font.pointSize: 32
	Layout.alignment: Qt.AlignHCenter
   }

   // Connection status text
   Text {
	id: statusText
	text: {
	 for (let i = 0; i < wifiManager.networks.length; i++) {
	  if (wifiManager.networks[i].connected) {
	   return tr("settings.system.wifi.connected.to") + ':';
	  }
	 }
	 return tr("settings.system.wifi.not.connected");
	}
	font.pointSize: 12
	color: {
	 for (let i = 0; i < wifiManager.networks.length; i++) {
	  if (wifiManager.networks[i].connected) {
	   return Colors.success;
	  }
	 }
	 return Colors.disabledForeground;
	}
	Layout.alignment: Qt.AlignHCenter
	horizontalAlignment: Text.AlignHCenter
	wrapMode: Text.WordWrap
	Layout.fillWidth: true
   }

   Text {
	id: connectedNetworkText
	text: {
	 for (let i = 0; i < wifiManager.networks.length; i++) {
	  if (wifiManager.networks[i].connected) {
	   return wifiManager.networks[i].name;
	  }
	 }
	}
	font.pointSize: 20
	font.bold: true
	Layout.alignment: Qt.AlignHCenter
	horizontalAlignment: Text.AlignHCenter
	wrapMode: Text.WordWrap
	Layout.fillWidth: true
	color: Colors.primaryText
   }

   // Signal strength for connected network
   SignalStrength {
	Layout.alignment: Qt.AlignHCenter
	Layout.preferredWidth: 50
	Layout.preferredHeight: 16
	strength: {
	 for (let i = 0; i < wifiManager.networks.length; i++) {
	  if (wifiManager.networks[i].connected)
	   return wifiManager.networks[i].strength;
	 }
	 return 0;
	}
	activeColor: Colors.success
	inactiveColor: Colors.disabledForeground
	visible: {
	 for (let i = 0; i < wifiManager.networks.length; i++) {
	  if (wifiManager.networks[i].connected) {
	   return true;
	  }
	 }
	 return false;
	}
   }
  }

  // Search button
  Button {
   id: searchButton
   Layout.fillWidth: true
   Layout.preferredHeight: root.height * 0.15
   text: tr("settings.system.wifi.search")

   background: Rectangle {
	color: searchButton.pressed ? "#0066cc" : (searchButton.hovered ? "#3399ff" : "#007bff")
	radius: 10
	border.color: "#0056b3"
	border.width: 1
   }

   contentItem: Text {
	text: searchButton.text
	font.pointSize: 14
	font.bold: true
	color: "white"
	horizontalAlignment: Text.AlignHCenter
	verticalAlignment: Text.AlignVCenter
   }

   onClicked: {
	root.wifiListRequested();
   }
  }
 }
}
