import QtQuick 2.15
import QtQuick.Controls 2.15
import "../static"

Item {
	id: root

	// Colors instance
	Colors {
		id: colors
	}

	// Custom signal for enter
	signal inputReturnPressed

	// Accessible properties for external configuration
	property real inputWidth: 300
	property real inputHeight: 50
	property real inputFontSize: 16
	property string inputPlaceholder: ""
	property int inputEchoMode: TextInput.Normal
	property bool inputAutoFocus: false

	// Input method hints for different input types
	property int inputMethodHints: Qt.ImhNone
	property string inputType: "text" // "text", "password", "number", "email", "multiline"
	property bool inputMultiline: false

	// Styling properties
	property color inputTextColor: colors.primaryForeground
	property color inputBackgroundColor: colors.primaryBackground
	property color inputBorderColor: colors.primaryForeground
	property real inputBorderWidth: 2
	property real inputBorderRadius: 10

	// Text property to access content
	property string text: inputMultiline ? textArea.text : textField.text

	// Active focus property for external tracking
	readonly property bool inputHasFocus: inputMultiline ? textArea.activeFocus : textField.activeFocus

	// Method to focus the input
	function forceActiveFocus() {
		if (inputMultiline) {
			textArea.forceActiveFocus();
		} else {
			textField.forceActiveFocus();
		}
	}

	// Method to clear focus
	function clearFocus() {
		if (inputMultiline) {
			textArea.focus = false;
		} else {
			textField.focus = false;
		}
	}

	// Apply properties
	width: inputWidth
	height: inputHeight

	// Single-line TextField
	TextField {
		id: textField
		visible: !root.inputMultiline
		anchors.fill: parent
		anchors.margins: root.inputBorderWidth
		font.pixelSize: root.inputFontSize
		placeholderText: root.inputPlaceholder
		color: root.inputTextColor
		background: Item {} // No background - using parent's

		Keys.onReturnPressed: {
			root.inputReturnPressed();
		}
	}

	// Multi-line TextArea
	ScrollView {
		id: scrollView
		visible: root.inputMultiline
		anchors.fill: parent
		anchors.margins: root.inputBorderWidth
		clip: true

		TextArea {
			id: textArea
			font.pixelSize: root.inputFontSize
			placeholderText: root.inputPlaceholder
			color: root.inputTextColor
			wrapMode: TextArea.Wrap
			background: Item {} // No background - using parent's

			Keys.onReturnPressed: function (event) {
				if (event.modifiers & Qt.ControlModifier) {
					root.inputReturnPressed();
				}
			}
		}
	}

	// Custom background for the entire component
	Rectangle {
		anchors.fill: parent
		color: root.inputBackgroundColor
		border.color: root.inputBorderColor
		border.width: root.inputBorderWidth
		radius: root.inputBorderRadius
		z: -1
	}

	// Set input method hints and echo mode based on input type
	Component.onCompleted: {
		switch (inputType) {
		case "password":
			if (!inputMultiline) {
				textField.echoMode = TextInput.Password;
				textField.inputMethodHints = Qt.ImhSensitiveData | Qt.ImhNoPredictiveText;
			}
			break;
		case "number":
			if (!inputMultiline) {
				textField.inputMethodHints = Qt.ImhDigitsOnly;
			}
			break;
		case "email":
			if (!inputMultiline) {
				textField.inputMethodHints = Qt.ImhEmailCharactersOnly;
			}
			break;
		case "multiline":
			inputMultiline = true;
			textArea.inputMethodHints = Qt.ImhMultiLine;
			break;
		default:
			if (!inputMultiline) {
				textField.echoMode = root.inputEchoMode;
				textField.inputMethodHints = root.inputMethodHints;
			}
		}

		// Set wrapMode for multiline inputs
		if (inputMultiline && textArea) {
			textArea.wrapMode = TextArea.Wrap;
		}

		if (inputAutoFocus) {
			root.forceActiveFocus();
		}
	}
}
