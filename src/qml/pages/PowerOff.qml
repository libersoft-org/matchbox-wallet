import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Rectangle {
 id: root
 color: "#f0f0f0"
 signal backRequested
 signal exitRequested
 signal rebootRequested
 signal shutdownRequested

 ColumnLayout {
  anchors.fill: parent
  anchors.margins: Math.max(20, root.width * 0.05)
  spacing: Math.max(20, root.height * 0.03)

  // Page title
  Text {
   text: qsTr("Power Options")
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

   // Exit Application button
   MenuButton {
    text: qsTr("Exit Application")
    backgroundColor: "#dc3545"
    onClicked: root.exitRequested()
   }

   // Reboot button
   MenuButton {
    text: qsTr("Reboot System")
    backgroundColor: "#fd7e14"
    onClicked: root.rebootRequested()
   }

   // Shutdown button
   MenuButton {
    text: qsTr("Shutdown System")
    backgroundColor: "#6c757d"
    onClicked: root.shutdownRequested()
   }

   // Back button
   MenuButton {
    text: qsTr("Back to Menu")
    backgroundColor: "#28a745"
    onClicked: root.backRequested()
   }
  }
 }
}
