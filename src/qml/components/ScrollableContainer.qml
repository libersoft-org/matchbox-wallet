import QtQuick 6.4
import QtQuick.Controls 6.4

Item {
	id: root
	default property alias content: contentItem.children
	property real topMargin: height * 0.05
	property real bottomMargin: height * 0.05
	property real leftMargin: width * 0.1
	property real rightMargin: width * 0.1

	// Debug background
	/*
	Rectangle {
		anchors.fill: parent
		color: colors.error
		opacity: 0.2
	}
	*/
	Flickable {
		id: flickable
		anchors.fill: parent
		contentWidth: width
		boundsBehavior: Flickable.StopAtBounds
		clip: true

		// Auto-calculate contentHeight based on content
		contentHeight: Math.max(contentItem.childrenRect.height + root.topMargin + root.bottomMargin, height)

		Item {
			id: contentItem
			width: flickable.width - root.leftMargin - root.rightMargin
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.top: parent.top
			anchors.topMargin: root.topMargin
			height: childrenRect.height
		}
	}

	// External scrollbar - only visible when scrolling
	ScrollBar {
		id: externalScrollBar
		anchors.right: parent.right
		anchors.top: flickable.top
		anchors.bottom: flickable.bottom
		anchors.rightMargin: 5
		width: 15
		policy: ScrollBar.AsNeeded
		orientation: Qt.Vertical
		visible: flickable.moving || flickable.dragging || pressed

		size: flickable.visibleArea.heightRatio

		contentItem: Rectangle {
			color: colors.primaryForeground
			opacity: 0.2
			radius: parent.width * 0.5
		}
	}

	// Connect the scrollbar to the flickable
	Component.onCompleted: {
		flickable.ScrollBar.vertical = externalScrollBar;
	}
}
