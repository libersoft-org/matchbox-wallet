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
	property int windowHeight: 640 // default fallback

	// Layout properties
	width: parent.width
	height: parent.parent.height * 0.15
	// Default enabled is true
	enabled: true
	background: Rectangle {
		color: control.enabled ? (control.pressed ? control.pressedColor : (control.hovered ? control.hoverColor : control.backgroundColor)) : AppConstants.disabledBackground
		radius: parent.parent.height	* 0.05
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
		font.pixelSize: control.height * 0.4
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
