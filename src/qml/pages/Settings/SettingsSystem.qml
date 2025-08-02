import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
 id: root
 color: "#f0f0f0"

 signal backRequested
 signal wifiSettingsRequested

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
	text: qsTr("← Back")

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
	text: qsTr("System Settings")
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

  // System settings menu container
  Rectangle {
   Layout.fillWidth: true
   Layout.fillHeight: true
   color: "white"
   border.color: "#cccccc"
   border.width: 1
   radius: 8

   ColumnLayout {
	anchors.fill: parent
	anchors.margins: 30
	spacing: 15

	// WiFi settings button
	Button {
	 id: wifiButton
	 Layout.fillWidth: true
	 Layout.preferredHeight: 60
	 text: qsTr("WiFi")

	 background: Rectangle {
	  color: wifiButton.pressed ? "#0066cc" : (wifiButton.hovered ? "#3399ff" : "#ffffff")
	  radius: 6
	  border.color: "#007bff"
	  border.width: 1
	 }

	 contentItem: RowLayout {
	  anchors.fill: parent
	  anchors.leftMargin: 20
	  anchors.rightMargin: 20

	  Text {
	   text: wifiButton.text
	   font.pointSize: 14
	   color: wifiButton.pressed || wifiButton.hovered ? "white" : "#007bff"
	   Layout.fillWidth: true
	   verticalAlignment: Text.AlignVCenter
	  }

	  Text {
	   text: "→"
	   font.pointSize: 16
	   color: wifiButton.pressed || wifiButton.hovered ? "white" : "#007bff"
	   verticalAlignment: Text.AlignVCenter
	  }
	 }

	 onClicked: {
	  root.wifiSettingsRequested();
	 }
	}

	// Spacer to push content to top
	Item {
	 Layout.fillHeight: true
	}
   }
  }
 }
}
