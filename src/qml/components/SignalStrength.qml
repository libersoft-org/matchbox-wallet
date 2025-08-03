import QtQuick 2.15
import "../"

Item {
	id: root
	property int strength: 0  // Signal strength (0-4)
	property color activeColor: Colors.success
	property color inactiveColor: Colors.disabledForeground

	Row {
		anchors.centerIn: parent
		spacing: parent.width * 0.1
		
		Repeater {
			model: 4
			Rectangle {
				width: (root.width - parent.spacing * 3) / 4
				height: root.height * (index + 1) / 4
				anchors.bottom: parent.bottom
				color: index < root.strength ? root.activeColor : root.inactiveColor
				radius: width * 0.2
			}
		}
	}
}
