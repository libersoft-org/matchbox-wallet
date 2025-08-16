import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
	id: root
	property string title: ""
	property bool showBackButton: true
	property bool showPowerButton: true
	signal backRequested
	signal powerRequested
	height: window.width * 0.16

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
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		anchors.leftMargin: parent.height + window.width * 0.02  // Always reserve space for back button
		anchors.rightMargin: parent.height + window.width * 0.02  // Always reserve space for power button
		text: root.title
		font.pixelSize: window.width * 0.05
		font.bold: true
		color: colors.primaryForeground
		wrapMode: Text.WordWrap
		horizontalAlignment: Text.AlignHCenter
		verticalAlignment: Text.AlignVCenter
		elide: Text.ElideRight
		maximumLineCount: 2
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
		onClicked: root.powerRequested()
	}
}
