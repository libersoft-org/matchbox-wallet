import QtQuick 6.4
import "../static"

Rectangle {
	id: root
	property alias contentItem: contentContainer
	property real borderRadius: window.width * 0.03
	property color backgroundColor: "transparent"
	property color borderColor: colors.primaryForeground
	property real borderWidth: window.width * 0.005
	property real padding: window.width * 0.03
	width: parent.width
	height: contentContainer.childrenRect.height + (padding * 2)
	color: backgroundColor
	radius: borderRadius
	border.color: borderColor
	border.width: borderWidth

	Colors {
		id: colors
	}

	// Content container for child items
	Item {
		id: contentContainer
		anchors.fill: parent
		anchors.margins: root.padding
	}

	// Default child property - items added to Frame will go into contentContainer
	default property alias children: contentContainer.children
}
