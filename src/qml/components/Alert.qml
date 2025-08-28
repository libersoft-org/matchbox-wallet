import QtQuick 6.4

Rectangle {
	id: root
	property string type: "error" // "info", "warning", "error"
	property string message: ""
	width: parent.width
	height: textItem.height + 20
	color: colors.primaryBackground
	border.color: {
		switch (type) {
		case "warning":
			return colors.warning;
		case "error":
			return colors.error;
		case "info":
		default:
			return colors.success;
		}
	}
	border.width: root.width * 0.01
	radius: 10

	Text {
		id: textItem
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		anchors.margins: 10
		color: {
			switch (root.type) {
			case "warning":
				return colors.warning;
			case "error":
				return colors.error;
			case "info":
			default:
				return colors.success;
			}
		}
		font.pixelSize: 14
		wrapMode: Text.WordWrap
		text: {
			var prefix = "";
			switch (root.type) {
			case "warning":
				prefix = "<b>Warning:</b> ";
				break;
			case "error":
				prefix = "<b>Error:</b> ";
				break;
			case "info":
			default:
				prefix = "<b>Info:</b> ";
				break;
			}
			return prefix + root.message;
		}
		textFormat: Text.RichText
	}
}
