import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
	id: root
	clip: true

	// Public API
	property string signalType: "X"
	property int signalStrength: 0
	property color backgroundColor: "transparent"
	property string pageId: ""
	property var pageComponent: null
	property var onNavigate: undefined  // function(pageComponent, pageId)

	color: backgroundColor

	MouseArea {
		anchors.fill: parent
		onClicked: {
			if (root.onNavigate) {
				root.onNavigate(root.pageComponent, root.pageId);
			}
		}
		onPressed: root.opacity = 0.7
		onReleased: root.opacity = 1.0
	}

	// Content with 10% padding based on parent's (StatusBar) height
	Item {
		id: content
		anchors.fill: parent
		anchors.margins: parent.height * 0.1

		// Type label on the left
		Text {
			id: typeText
			text: root.signalType
			color: colors.primaryForeground
			font.pixelSize: parent.height
			font.bold: true
			anchors.left: parent.left
			anchors.verticalCenter: parent.verticalCenter
		}

		// Signal strength bars fill remaining space to the right
		Item {
			id: strengthBox
			anchors.left: typeText.right
			anchors.leftMargin: parent.height * 0.1
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			// anchors.verticalCenter conflicts with specifying both top and bottom

			SignalStrength {
				anchors.fill: parent
				strength: root.signalStrength
			}

			CrossOut {
				anchors.fill: parent
				visible: root.signalStrength === 0
			}
		}
	}
}
