import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Button {
	id: control
	// Vlastní properties
	property color backgroundColor: "#007bff"
	property color hoverColor: Qt.lighter(backgroundColor, 1.3)
	property color pressedColor: Qt.darker(backgroundColor, 1.2)
	property color borderColor: Qt.darker(backgroundColor, 1.1)
	property color textColor: "white"
	// Layout properties
	Layout.fillWidth: true
	Layout.preferredHeight: Math.max(50, parent.height * 0.08)
	Layout.maximumHeight: 80

	// Defaultní enabled je true
	enabled: true

	background: Rectangle {
		color: control.enabled ? (control.pressed ? control.pressedColor : (control.hovered ? control.hoverColor : control.backgroundColor)) : "#cccccc"
		radius: 6
		border.color: control.enabled ? control.borderColor : "#999999"
		border.width: 1

		// Animace pro hover efekt
		Behavior on color {
			ColorAnimation {
				duration: 150
			}
		}
	}

	contentItem: Text {
		text: control.text
		font.family: "Droid Sans"
		font.pointSize: Math.max(10, Math.min(16, control.height * 0.25))
		color: control.enabled ? control.textColor : "#666666"
		horizontalAlignment: Text.AlignHCenter
		verticalAlignment: Text.AlignVCenter

		// Animace pro disabled stav
		Behavior on color {
			ColorAnimation {
				duration: 150
			}
		}
	}
}
