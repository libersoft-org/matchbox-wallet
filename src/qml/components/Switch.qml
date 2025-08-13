import QtQuick 2.15
import QtQuick.Controls 2.15

Switch {
	id: control
	property color backgroundColor: colors.primaryBackground

	indicator: Rectangle {
		implicitHeight: window.width * 0.07
		implicitWidth: window.width * 0.12
		x: control.leftPadding
		y: parent.height / 2 - height / 2
		radius: width / 2
		color: colors.disabledForeground
		border.width: control.height * 0.05
		border.color: colors.primaryForeground

		Rectangle {
			x: control.checked ? (parent.width - width) - 2 : 2
			width: parent.height * 0.85
			height: parent.height * 0.85
			radius: height / 2
			color: control.checked ? colors.primaryForeground : colors.disabledBackground
			anchors.verticalCenter: parent.verticalCenter
		}
	}

	contentItem: Label {
		color: colors.primaryForeground
		text: control.text
		font.pixelSize: 16
		verticalAlignment: Text.AlignVCenter
		leftPadding: control.indicator.width + control.spacing
	}
}
