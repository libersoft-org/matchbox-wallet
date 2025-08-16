import QtQuick 2.15
import QtQuick.Controls 2.15
import "../static"

RadioButton {
	id: control

	Colors {
		id: colors
	}

	contentItem: Text {
		text: control.text
		font: control.font
		color: colors.primaryForeground
		leftPadding: control.indicator.width + control.spacing
		verticalAlignment: Text.AlignVCenter
	}

	indicator: Rectangle {
		implicitWidth: window.width * 0.05
		implicitHeight: window.width * 0.05
		x: control.leftPadding
		y: parent.height / 2 - height / 2
		radius: implicitHeight * 0.5
		border.color: control.checked ? colors.primaryForeground : colors.disabledForeground
		border.width: 2
		color: "transparent"

		Rectangle {
			width: parent.width * 0.5
			height: parent.height * 0.5
			x: parent.width * 0.25
			y: parent.height * 0.25
			radius: width * 0.5
			color: colors.primaryForeground
			visible: control.checked
		}
	}
}
