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
		implicitWidth: 20
		implicitHeight: 20
		x: control.leftPadding
		y: parent.height / 2 - height / 2
		radius: 10
		border.color: control.checked ? colors.primaryForeground : colors.disabledForeground
		border.width: 2
		color: "transparent"

		Rectangle {
			width: 10
			height: 10
			x: 5
			y: 5
			radius: 5
			color: colors.primaryForeground
			visible: control.checked
		}
	}
}
