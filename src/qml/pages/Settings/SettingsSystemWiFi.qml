import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0

Rectangle {
 id: root
 color: "#f0f0f0"

 signal backRequested

 // WiFi Manager instance
 WiFiManager {
  id: wifiManager

  onConnectionResult: function (ssid, success, error) {
   if (success) {
	console.log("Successfully connected to", ssid);
   } else {
	console.log("Failed to connect to", ssid, "Error:", error);
	// You could show an error dialog here
   }
  }
 }

 // Scan on component load
 Component.onCompleted: {
  wifiManager.scanNetworks();
 }

 ColumnLayout {
  anchors.fill: parent
  anchors.margins: 20
  spacing: 20

  // Header with back button and title
  RowLayout {
   Layout.fillWidth: true

   Button {
	id: backButton
	Layout.preferredWidth: 80
	Layout.preferredHeight: 40
	text: qsTr("Back")

	background: Rectangle {
	 color: backButton.pressed ? "#e0e0e0" : (backButton.hovered ? "#f0f0f0" : "#f8f9fa")
	 radius: 6
	 border.color: "#6c757d"
	 border.width: 1
	}

	contentItem: Text {
	 text: backButton.text
	 font.pointSize: 10
	 color: "#333333"
	 horizontalAlignment: Text.AlignHCenter
	 verticalAlignment: Text.AlignVCenter
	}

	onClicked: {
	 root.backRequested();
	}
   }

   Text {
	text: qsTr("WiFi Networks")
	font.pointSize: 24
	font.bold: true
	color: "#333333"
	Layout.alignment: Qt.AlignHCenter
	Layout.fillWidth: true
	horizontalAlignment: Text.AlignHCenter
   }

   // Spacer to center the title
   Item {
	Layout.preferredWidth: 80
   }
  }

  // WiFi list container
  Rectangle {
   Layout.fillWidth: true
   Layout.fillHeight: true
   color: "white"
   border.color: "#cccccc"
   border.width: 1
   radius: 8

   ColumnLayout {
	anchors.fill: parent
	anchors.margins: 20
	spacing: 10

	// Refresh button
	Button {
	 id: refreshButton
	 Layout.preferredWidth: 120
	 Layout.preferredHeight: 35
	 text: wifiManager.isScanning ? qsTr("Scanning...") : qsTr("🔄 Refresh")
	 Layout.alignment: Qt.AlignRight
	 enabled: !wifiManager.isScanning

	 background: Rectangle {
	  color: refreshButton.enabled ? (refreshButton.pressed ? "#0066cc" : (refreshButton.hovered ? "#3399ff" : "#007bff")) : "#6c757d"
	  radius: 6
	  border.color: "#0056b3"
	  border.width: 1
	 }

	 contentItem: Text {
	  text: refreshButton.text
	  font.pointSize: 10
	  color: "white"
	  horizontalAlignment: Text.AlignHCenter
	  verticalAlignment: Text.AlignVCenter
	 }

	 onClicked: {
	  wifiManager.scanNetworks();
	 }
	}

	// WiFi networks list
	ScrollView {
	 Layout.fillWidth: true
	 Layout.fillHeight: true

	 ListView {
	  id: wifiListView
	  model: wifiManager.networks
	  spacing: 5

	  delegate: Rectangle {
	   width: wifiListView.width
	   height: 70
	   color: mouseArea.pressed ? "#f0f8ff" : (mouseArea.containsMouse ? "#f8f9fa" : "white")
	   border.color: modelData.connected ? "#28a745" : "#dee2e6"
	   border.width: modelData.connected ? 2 : 1
	   radius: 6

	   MouseArea {
		id: mouseArea
		anchors.fill: parent
		hoverEnabled: true

		onClicked: {
		 if (!modelData.connected) {
		  connectDialog.networkName = modelData.name;
		  connectDialog.isSecured = modelData.secured;
		  connectDialog.open();
		 }
		}
	   }

	   RowLayout {
		anchors.fill: parent
		anchors.margins: 15
		spacing: 15

		// WiFi icon and signal strength
		Column {
		 Layout.preferredWidth: 40
		 spacing: 2

		 Text {
		  text: "📶"
		  font.pointSize: 16
		  anchors.horizontalCenter: parent.horizontalCenter
		 }

		 // Signal strength indicator
		 Row {
		  spacing: 2
		  anchors.horizontalCenter: parent.horizontalCenter

		  Repeater {
		   model: 4
		   Rectangle {
			width: 3
			height: (index + 1) * 3
			color: index < modelData.strength ? "#28a745" : "#dee2e6"
		   }
		  }
		 }
		}

		// Network info
		Column {
		 Layout.fillWidth: true
		 spacing: 5

		 RowLayout {
		  Layout.fillWidth: true

		  Text {
		   text: modelData.name
		   font.pointSize: 12
		   font.bold: modelData.connected
		   color: "#333333"
		   Layout.fillWidth: true
		  }

		  Text {
		   text: modelData.secured ? "🔒" : "🔓"
		   font.pointSize: 12
		  }
		 }

		 Text {
		  text: modelData.connected ? qsTr("Connected") : qsTr("Available")
		  font.pointSize: 10
		  color: modelData.connected ? "#28a745" : "#6c757d"
		 }
		}

		// Connect button or status
		Item {
		 Layout.preferredWidth: 80

		 Text {
		  text: modelData.connected ? "✓" : "→"
		  font.pointSize: 16
		  color: modelData.connected ? "#28a745" : "#007bff"
		  anchors.centerIn: parent
		 }
		}
	   }
	  }
	 }
	}
   }
  }
 }

 // WiFi connection dialog
 Dialog {
  id: connectDialog
  title: qsTr("Connect to WiFi")
  modal: true
  anchors.centerIn: parent
  width: 350
  height: isSecured ? 200 : 150

  property string networkName: ""
  property bool isSecured: false

  contentItem: Rectangle {
   color: "white"

   ColumnLayout {
	anchors.fill: parent
	anchors.margins: 20
	spacing: 15

	Text {
	 text: qsTr("Connect to network: %1").arg(connectDialog.networkName)
	 wrapMode: Text.WordWrap
	 Layout.fillWidth: true
	 font.bold: true
	}

	// Password field (only for secured networks)
	ColumnLayout {
	 Layout.fillWidth: true
	 visible: connectDialog.isSecured
	 spacing: 5

	 Text {
	  text: qsTr("Password:")
	  font.pointSize: 10
	 }

	 TextField {
	  id: passwordField
	  Layout.fillWidth: true
	  echoMode: TextInput.Password
	  placeholderText: qsTr("Enter password...")
	 }
	}

	Text {
	 text: connectDialog.isSecured ? "" : qsTr("This is an open network.")
	 visible: !connectDialog.isSecured
	 font.pointSize: 10
	 color: "#6c757d"
	}

	RowLayout {
	 Layout.alignment: Qt.AlignHCenter
	 spacing: 10

	 Button {
	  text: qsTr("Cancel")
	  onClicked: {
	   passwordField.text = "";
	   connectDialog.close();
	  }

	  background: Rectangle {
	   color: parent.pressed ? "#e0e0e0" : (parent.hovered ? "#f0f0f0" : "#f8f9fa")
	   radius: 4
	   border.color: "#6c757d"
	   border.width: 1
	  }
	 }

	 Button {
	  text: qsTr("Connect")
	  onClicked: {
	   wifiManager.connectToNetwork(connectDialog.networkName, passwordField.text);
	   passwordField.text = "";
	   connectDialog.close();
	  }

	  background: Rectangle {
	   color: parent.pressed ? "#0066cc" : (parent.hovered ? "#3399ff" : "#007bff")
	   radius: 4
	   border.color: "#0056b3"
	   border.width: 1
	  }

	  contentItem: Text {
	   text: parent.text
	   color: "white"
	   horizontalAlignment: Text.AlignHCenter
	   verticalAlignment: Text.AlignVCenter
	  }
	 }
	}
   }
  }
 }
}
