import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0

Button {
	id: control
	property color backgroundColor: AppConstants.primaryBackground
	property color hoverColor: Qt.darker(backgroundColor, 1.3)
	property color pressedColor: Qt.darker(backgroundColor, 1.2)
	property color borderColor: Qt.darker(backgroundColor, 1.1)
	property color textColor: AppConstants.primaryForeground
	
	// Accept window dimensions from parent to avoid binding loops
	property int windowHeight: 640 // default fallback
	
	// Layout properties
	Layout.fillWidth: true
	Layout.preferredHeight: Math.max(50, windowHeight * 0.08)
	Layout.maximumHeight: windowHeight * 0.12
	// Default enabled is true
	enabled: true
	background: Rectangle {
		color: control.enabled ? (control.pressed ? control.pressedColor : (control.hovered ? control.hoverColor : control.backgroundColor)) : AppConstants.disabledBackground
		radius: 10
		border.color: control.enabled ? control.borderColor : AppConstants.disabledForeground
		border.width: 1
		// Animation for hover effect
		Behavior on color {
			ColorAnimation {
				duration: 150
			}
		}
	}

	contentItem: Text {
		text: control.text
		font.pixelSize: control.height * 0.5
		font.bold: true
		color: control.enabled ? control.textColor : AppConstants.disabledForeground
		horizontalAlignment: Text.AlignHCenter
		verticalAlignment: Text.AlignVCenter
		// Animation for disabled state
		Behavior on color {
			ColorAnimation {
				duration: 150
			}
		}
	}
}
