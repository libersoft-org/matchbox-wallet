import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.VirtualKeyboard
import "../components"
import "../static"

Page {
	id: root

	// Colors instance
	Colors {
		id: colors
	}

	// Set background color
	background: Rectangle {
		color: colors.primaryBackground
	}

	// Property to track if any input has focus
	property bool anyInputHasFocus: textField1.inputHasFocus || textField2.inputHasFocus || passwordField.inputHasFocus || numberField.inputHasFocus || textArea.inputHasFocus

	// Ensure page has focus initially so no input is focused
	Component.onCompleted: {
		root.forceActiveFocus();
		inputPanel.state = "hidden";
	}

	Flickable {
		id: flickable
		anchors.fill: parent
		anchors.margins: 20
		contentHeight: column.height
		clip: true

		// Add MouseArea to detect clicks outside inputs
		MouseArea {
			anchors.fill: parent
			onPressed: function (mouse) {
				// Clear focus from all inputs when clicking in empty space
				textField1.clearFocus();
				textField2.clearFocus();
				passwordField.clearFocus();
				numberField.clearFocus();
				textArea.clearFocus();
				// Set focus to page to ensure keyboard hides
				root.forceActiveFocus();
				// Don't accept the event so it propagates to child items
				mouse.accepted = false;
			}
		}

		Column {
			id: column
			width: parent.width
			spacing: 20

			Text {
				text: "Test Qt Virtual Keyboard s našimi Input komponenty:"
				font.pixelSize: 18
				color: colors.primaryForeground
				wrapMode: Text.WordWrap
			}

			Input {
				id: textField1
				inputWidth: parent.width
				inputPlaceholder: "Single line text field..."
				inputType: "text"
				onInputReturnPressed: textField2.forceActiveFocus()
			}

			Input {
				id: textField2
				inputWidth: parent.width
				inputPlaceholder: "Email field..."
				inputType: "email"
				onInputReturnPressed: passwordField.forceActiveFocus()
			}

			Input {
				id: passwordField
				inputWidth: parent.width
				inputPlaceholder: "Password field..."
				inputType: "password"
				onInputReturnPressed: numberField.forceActiveFocus()
			}

			Input {
				id: numberField
				inputWidth: parent.width
				inputPlaceholder: "Number field..."
				inputType: "number"
				onInputReturnPressed: textArea.forceActiveFocus()
			}

			Input {
				id: textArea
				inputWidth: parent.width
				inputHeight: 100
				inputPlaceholder: "Multi-line text area..."
				inputType: "multiline"
			}

			Text {
				text: "Results:"
				font.pixelSize: 16
				font.bold: true
				color: colors.primaryForeground
			}

			Text {
				text: "Text field: " + textField1.text
				font.pixelSize: 14
				color: colors.primaryForeground
				wrapMode: Text.WordWrap
			}

			Text {
				text: "Email: " + textField2.text
				font.pixelSize: 14
				color: colors.primaryForeground
				wrapMode: Text.WordWrap
			}

			Text {
				text: "Password: " + "*".repeat(passwordField.text.length)
				font.pixelSize: 14
				color: colors.primaryForeground
			}

			Text {
				text: "Number: " + numberField.text
				font.pixelSize: 14
				color: colors.primaryForeground
			}

			Text {
				text: "Text area: " + textArea.text
				font.pixelSize: 14
				color: colors.primaryForeground
				wrapMode: Text.WordWrap
			}
		}
	}

	InputPanel {
		id: inputPanel
		z: 99
		x: 0
		width: root.width
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom

		// Start hidden by positioning below the screen
		y: root.height
		state: "hidden"

		// Handle hide button on keyboard
		onActiveChanged: {
			if (!active) {
				// User pressed hide button, clear focus from all inputs
				textField1.clearFocus();
				textField2.clearFocus();
				passwordField.clearFocus();
				numberField.clearFocus();
				textArea.clearFocus();
				root.forceActiveFocus();
			}
		}

		// Show keyboard only when any input has focus
		states: [
			State {
				name: "hidden"
				when: !root.anyInputHasFocus
				PropertyChanges {
					inputPanel.y: root.height
					inputPanel.visible: false
				}
			},
			State {
				name: "visible"
				when: root.anyInputHasFocus
				PropertyChanges {
					inputPanel.y: root.height - inputPanel.height
					inputPanel.visible: true
				}
			}
		]

		transitions: [
			Transition {
				from: "hidden"
				to: "visible"
				SequentialAnimation {
					PropertyAction {
						property: "visible"
						value: true
					}
					NumberAnimation {
						property: "y"
						duration: 250
						easing.type: Easing.InOutQuad
					}
				}
			},
			Transition {
				from: "visible"
				to: "hidden"
				SequentialAnimation {
					NumberAnimation {
						property: "y"
						duration: 250
						easing.type: Easing.InOutQuad
					}
					PropertyAction {
						property: "visible"
						value: false
					}
				}
			}
		]

		// Adjust flickable when keyboard shows/hides
		onStateChanged: {
			if (state === "visible") {
				// Keyboard is showing - adjust flickable
				flickable.anchors.bottomMargin = inputPanel.height + 10;
			} else {
				// Keyboard is hiding - restore flickable
				flickable.anchors.bottomMargin = 0;
			}
		}
	}
}
