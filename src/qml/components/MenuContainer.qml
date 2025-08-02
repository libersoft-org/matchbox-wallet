import QtQuick 2.15
import QtQuick.Controls 2.15
import WalletModule 1.0

Item {
	id: root
	default property alias buttons: buttonsContainer.children
	
	// Debug background
	/*
	Rectangle {
		anchors.fill: parent
		color: "#800"
		opacity: 0.2
	}
	*/
	// Automatically set windowHeight for all MenuButton children
	onButtonsChanged: {
		for (let i = 0; i < buttons.length; i++) {
			if (buttons[i].hasOwnProperty('windowHeight')) {
				buttons[i].windowHeight = Qt.binding(function() { return root.height; });
			}
			if (buttons[i].hasOwnProperty('flickableHeight')) {
				buttons[i].flickableHeight = Qt.binding(function() { return flickable.height; });
			}
		}
	}
	
	Flickable {
		id: flickable
		anchors.fill: parent
		contentWidth: width
		boundsBehavior: Flickable.StopAtBounds
		clip: true
		
		// Explicit calculation of contentHeight
		property real calculatedContentHeight: {
			var totalHeight = 0;
			for (var i = 0; i < buttonsContainer.children.length; i++) {
				var child = buttonsContainer.children[i];
				if (child && child.height) {
					totalHeight += child.height;
				}
			}
			if (buttonsContainer.children.length > 1) totalHeight += (buttonsContainer.children.length - 1) * buttonsContainer.spacing;
			totalHeight += flickable.height * 0.1 - buttonsContainer.spacing; // top margin
			return totalHeight;
		}
		
		contentHeight: Math.max(calculatedContentHeight, height)
		
		Column {
			id: buttonsContainer
			width: flickable.width - flickable.width * 0.1
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.top: parent.top
			anchors.topMargin: flickable.height * 0.05
			anchors.bottom: parent.bottom
			anchors.bottomMargin: flickable.height * 0.05 // bottom margin
			spacing: root.height * 0.03
		}
	}
	
	// External scrollbar outside of Flickable - only visible when scrolling
	ScrollBar {
		id: externalScrollBar
		anchors.right: parent.right
		anchors.top: flickable.top
		anchors.bottom: flickable.bottom
		anchors.rightMargin: 5
		width: 15
		policy: ScrollBar.AsNeeded
		orientation: Qt.Vertical
		visible: flickable.moving || flickable.dragging || pressed // Only visible when actively scrolling
		size: flickable.visibleArea.heightRatio
		position: flickable.visibleArea.yPosition
		contentItem: Rectangle {
			color: AppConstants.primaryForeground
			opacity: 0.2
			radius: parent.width * 0.5
		}
		
		onPositionChanged: {
			if (pressed && size < 1.0) {
				flickable.contentY = position * (flickable.contentHeight - flickable.height)
			}
		}
	}
}
