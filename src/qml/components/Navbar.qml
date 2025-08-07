import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
 id: root

 // Local alias for easier access to colors
 property var colors: window.colors

 property string title: ""
 property bool showBackButton: true
 property bool showPowerButton: true
 signal backRequested
 signal powerOffRequested
 height: parent.height * 0.1

 // Debug background
 /*
	Rectangle {
		anchors.fill: parent
		color: "red"
		opacity: 0.3
	}
	*/

 // Back button (left)
 Icon {
  id: backButton
  visible: root.showBackButton
  anchors.left: parent.left
  anchors.verticalCenter: parent.verticalCenter
  width: parent.height
  height: parent.height
  img: Qt.resolvedUrl("../../img/back.svg")
  onClicked: root.backRequested()
 }

 // Title text (center)
 Text {
  anchors.centerIn: parent
  text: root.title
  font.pixelSize: parent.height * 0.4
  font.bold: true
  color: colors.primaryForeground
 }

 // Power button (right)
 Icon {
  id: powerButton
  visible: root.showPowerButton
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  width: parent.height
  height: parent.height
  img: Qt.resolvedUrl("../../img/power.svg")
  onClicked: root.powerOffRequested()
 }
}
