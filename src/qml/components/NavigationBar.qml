import QtQuick 2.15
import QtQuick.Controls 2.15
import WalletModule 1.0

Item {
	id: root
	property string title: ""
	property bool showBackButton: true
	property bool showPowerButton: true
	signal backRequested
	signal powerOffRequested
	height: parent.height * 0.1
	
	// Debug background
	Rectangle {
		anchors.fill: parent
		color: "red"
		opacity: 0.3
	}
	
	// Back button (left)
	Button {
		id: backButton
		visible: root.showBackButton
		anchors.left: parent.left
		anchors.verticalCenter: parent.verticalCenter
		width: parent.height
		height: parent.height
		background: Rectangle {
			color: "lightblue"
			opacity: 0.3
		}
		contentItem: Image {
			anchors.fill: parent
			source: "qrc:/WalletModule/src/img/back.svg"
			fillMode: Image.PreserveAspectFit
			sourceSize.width: parent.width
			sourceSize.height: parent.height
		}
		onClicked: root.backRequested()
	}

	// Title text (center)
	Text {
		anchors.centerIn: parent
		text: root.title
		font.pixelSize: parent.height * 0.5
		font.bold: true
		color: AppConstants.primaryForeground
	}
	
	// Power button (right)
	Button {
		id: powerButton
		visible: root.showPowerButton
		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		width: parent.height
		height: parent.height
		background: Rectangle {
			color: "lightgreen"
			opacity: 0.3
		}
		contentItem: Image {
			anchors.fill: parent
			source: "qrc:/WalletModule/src/img/power.svg"
			fillMode: Image.PreserveAspectFit
			sourceSize.width: parent.width
			sourceSize.height: parent.height
		}
		onClicked: root.powerOffRequested()
	}
}
