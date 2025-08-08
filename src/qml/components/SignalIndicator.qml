import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
	id: root

	// Public API
	property string signalType: "X"
	property int signalStrength: 0
	property color backgroundColor: "transparent"
	property string pageId: ""
	property var pageComponent: null
	property var colors: undefined      // expect colors palette to be passed in
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

	Row {
		spacing: root.height * 0.1
		width: parent.width * 0.8
		height: parent.height * 0.8

		Text {
			text: root.signalType
			color: root.colors ? root.colors.primaryForeground : "white"
			font.pixelSize: parent.height
			font.bold: true
			anchors.verticalCenter: parent.verticalCenter
		}

		Item {
			width: parent.width
			height: parent.height
			anchors.verticalCenter: parent.verticalCenter

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
