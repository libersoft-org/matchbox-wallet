import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0

Item {
	id: root

	property string title: ""
	default property alias buttons: buttonsContainer.children
	
	// Automatically set windowHeight for all MenuButton children
	onButtonsChanged: {
		for (let i = 0; i < buttons.length; i++) {
			if (buttons[i].hasOwnProperty('windowHeight')) {
				buttons[i].windowHeight = Qt.binding(function() { return root.height; });
			}
		}
	}
	
	// Title area
	Item {
		id: titleBackground
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		height: parent.height * 0.1

		Text {
			anchors.centerIn: parent
			text: root.title
			font.pixelSize: parent.height * 0.5
			font.bold: true
			color: AppConstants.primaryForeground
		}
	}
	
	// Button area
	Item {
		id: buttonsBackground
		anchors.top: titleBackground.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		
		ScrollView {
			id: scrollView
			anchors.fill: parent
			anchors.leftMargin: parent.width * 0.05
			anchors.rightMargin: parent.width * 0.05
			ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
			ScrollBar.vertical.policy: ScrollBar.AsNeeded
			contentWidth: availableWidth
			contentHeight: buttonsContainer.implicitHeight
			
			// Debug background
			Rectangle {
				anchors.fill: parent
				color: "red"
				opacity: 0.3
			}
			
			Column {
				id: buttonsContainer
				width: scrollView.availableWidth
				spacing: root.height * 0.03
			}
		}
	}
}
