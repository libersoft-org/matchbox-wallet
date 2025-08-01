import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Rectangle {
 id: root
 color: "#f0f0f0"
 signal settingsRequested
 signal powerOffRequested
 signal cameraPreviewRequested

 ColumnLayout {
  anchors.fill: parent
  anchors.margins: Math.max(20, root.width * 0.05)
  spacing: Math.max(20, root.height * 0.03)

  // App title
  Text {
   text: qsTr("Yellow Matchbox Wallet")
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
   Layout.leftMargin: 15
   Layout.rightMargin: 15
   spacing: Math.max(15, root.height * 0.05)

   // Settings button
   MenuButton {
	text: qsTr("Settings")
	onClicked: root.settingsRequested()
   }

   MenuButton {
				text: qsTr("Test camera")
				backgroundColor: "#008800"
				onClicked: root.cameraPreviewRequested()
   }

   MenuButton {
	text: qsTr("Yellow button")
	backgroundColor: "#fd1"
	onClicked: console.log("Yellow button clicked")
   }

   MenuButton {
	text: qsTr("Disabled button")
	backgroundColor: "#0000FF"
	textColor: "#212529"
	enabled: false
   }

   // Power off button
   MenuButton {
	text: qsTr("Power off")
	backgroundColor: "#dc3545"
	onClicked: root.powerOffRequested()
   }
  }
 }
}
