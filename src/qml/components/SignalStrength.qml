import QtQuick 6.8

Item {
	id: root
	property int strength: 0  // Signal strength (0-4)

	Row {
		anchors.centerIn: parent
		spacing: parent.width * 0.1

		Repeater {
			model: 4
			Rectangle {
				width: (root.width - parent.spacing * 3) / 4
				height: root.height * (index + 1) / 4
				anchors.bottom: parent.bottom
				color: index < root.strength ? colors.success : colors.disabledForeground
				radius: width * 0.2
			}
		}
	}
}
