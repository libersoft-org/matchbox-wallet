import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
 id: root
 color: "#f0f0f0"

 signal settingsRequested
 signal powerOffRequested

 ColumnLayout {
  anchors.fill: parent
  anchors.margins: Math.max(20, root.width * 0.05)
  spacing: Math.max(20, root.height * 0.03)

  // App title
  Text {
   text: qsTr("Main Menu")
   font.pointSize: Math.max(18, Math.min(36, root.width * 0.04))
   font.bold: true
   color: "#333333"
   Layout.alignment: Qt.AlignHCenter
   Layout.topMargin: Math.max(20, root.height * 0.05)
  }

  // Menu buttons container
  ColumnLayout {
   Layout.fillWidth: true
   Layout.fillHeight: true
   Layout.leftMargin: 20
   Layout.rightMargin: 20
   spacing: Math.max(15, root.height * 0.05)

   // Settings button
   MenuButton {
	text: qsTr("Settings")
	backgroundColor: "#007bff"
	onClicked: root.settingsRequested()
   }

   // Separator
   Rectangle {
	Layout.fillWidth: true
	Layout.preferredHeight: 1
	Layout.leftMargin: 10
	Layout.rightMargin: 10
	color: "#dddddd"
   }

   // WiFi Settings button
   MenuButton {
	text: qsTr("WiFi Settings")
	backgroundColor: "#28a745"
	onClicked: console.log("WiFi Settings clicked")
   }

   // System Info button
   MenuButton {
	text: qsTr("System Info")
	backgroundColor: "#17a2b8"
	onClicked: console.log("System Info clicked")
   }

   // Disabled button example
   MenuButton {
	text: qsTr("Maintenance Mode")
	backgroundColor: "#ffc107"
	textColor: "#212529"
	enabled: false
   }

   // Separator
   Rectangle {
	Layout.fillWidth: true
	Layout.preferredHeight: 1
	Layout.leftMargin: 10
	Layout.rightMargin: 10
	color: "#dddddd"
   }

   // Power off button
   MenuButton {
	text: qsTr("Power Off")
	backgroundColor: "#dc3545"
	onClicked: powerOffDialog.open()
   }
  }

  // App info
  Text {
   text: qsTr("Version: %1").arg(applicationVersion || "1.0.0")
   font.pointSize: Math.max(8, Math.min(12, root.width * 0.015))
   color: "#666666"
   Layout.alignment: Qt.AlignHCenter
   Layout.bottomMargin: Math.max(20, root.height * 0.03)
  }
 }

 // Power off confirmation dialog
 Dialog {
  id: powerOffDialog
  title: qsTr("Confirm Power Off")
  modal: true
  anchors.centerIn: parent
  width: Math.max(300, root.width * 0.4)
  height: Math.max(150, root.height * 0.25)

  contentItem: Rectangle {
   color: "white"

   ColumnLayout {
	anchors.fill: parent
	anchors.margins: 20
	spacing: 15

	Text {
	 text: qsTr("Are you sure you want to exit the application?")
	 wrapMode: Text.WordWrap
	 Layout.fillWidth: true
	 horizontalAlignment: Text.AlignHCenter
	 font.pointSize: Math.max(10, Math.min(14, powerOffDialog.width * 0.03))
	}

	RowLayout {
	 Layout.alignment: Qt.AlignHCenter
	 spacing: 10

	 Button {
	  text: qsTr("Cancel")
	  Layout.preferredWidth: Math.max(80, powerOffDialog.width * 0.25)
	  Layout.preferredHeight: Math.max(35, powerOffDialog.height * 0.2)
	  onClicked: powerOffDialog.close()

	  background: Rectangle {
	   color: parent.pressed ? "#e0e0e0" : (parent.hovered ? "#f0f0f0" : "#f8f9fa")
	   radius: 4
	   border.color: "#6c757d"
	   border.width: 1
	  }

	  contentItem: Text {
	   text: parent.text
	   font.pointSize: Math.max(9, Math.min(12, parent.height * 0.25))
	   horizontalAlignment: Text.AlignHCenter
	   verticalAlignment: Text.AlignVCenter
	  }
	 }

	 Button {
	  text: qsTr("Exit")
	  Layout.preferredWidth: Math.max(80, powerOffDialog.width * 0.25)
	  Layout.preferredHeight: Math.max(35, powerOffDialog.height * 0.2)
	  onClicked: {
	   powerOffDialog.close();
	   root.powerOffRequested();
	  }

	  background: Rectangle {
	   color: parent.pressed ? "#cc0000" : (parent.hovered ? "#ff3333" : "#dc3545")
	   radius: 4
	   border.color: "#b02a37"
	   border.width: 1
	  }

	  contentItem: Text {
	   text: parent.text
	   color: "white"
	   font.pointSize: Math.max(9, Math.min(12, parent.height * 0.25))
	   horizontalAlignment: Text.AlignHCenter
	   verticalAlignment: Text.AlignVCenter
	  }
	 }
	}
   }
  }
 }
}
