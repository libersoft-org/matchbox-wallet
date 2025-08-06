import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

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
		color: window.colors.error
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
   color: window.colors.primaryForeground
   opacity: 0.2
   radius: parent.width * 0.5
  }
 }

 // Connect the scrollbar to the flickable
 Component.onCompleted: {
  flickable.ScrollBar.vertical = externalScrollBar;
 }
}
