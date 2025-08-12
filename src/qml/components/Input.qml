import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
	id: root
	// Custom signal for enter
	signal inputReturnPressed

	// Accessible properties for external configuration
	property real inputWidth: 300
	property real inputHeight: 50
	property real inputFontSize: 16
	property string inputPlaceholder: ""
	property int inputEchoMode: TextInput.Normal
	property bool inputAutoFocus: false

	// Styling properties
	property color inputTextColor: colors.primaryForeground
	property color inputBackgroundColor: colors.primaryBackground
	property color inputBorderColor: colors.primaryForeground
	property real inputBorderWidth: 2
	property real inputBorderRadius: 10

	// Apply properties
	width: inputWidth
	height: inputHeight
	font.pixelSize: inputFontSize
	placeholderText: inputPlaceholder
	echoMode: inputEchoMode
	color: inputTextColor

	// Custom background
	background: Rectangle {
		color: root.inputBackgroundColor
		border.color: root.inputBorderColor
		border.width: root.inputBorderWidth
		radius: root.inputBorderRadius
	}

	// Auto focus
	Component.onCompleted: {
		if (inputAutoFocus) {
			root.forceActiveFocus();
		}
	}

	Keys.onReturnPressed: {
		root.inputReturnPressed();
	}
}
