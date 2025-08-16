import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../"
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.calculator.title")
	property bool showBackButton: true

	property string display: "0"
	property string operation: ""
	property real leftOperand: 0
	property real rightOperand: 0
	property bool waitingForOperand: true
	property bool hasDecimal: false

	function clearAll() {
		display = "0";
		operation = "";
		leftOperand = 0;
		rightOperand = 0;
		waitingForOperand = true;
		hasDecimal = false;
	}

	function addDigit(digit) {
		if (waitingForOperand) {
			display = digit;
			waitingForOperand = false;
		} else {
			if (display === "0") {
				display = digit;
			} else {
				display += digit;
			}
		}
	}

	function addDecimal() {
		if (waitingForOperand) {
			display = "0.";
			waitingForOperand = false;
			hasDecimal = true;
		} else if (!hasDecimal) {
			display += ".";
			hasDecimal = true;
		}
	}

	function performOperation(op) {
		var result = 0;

		if (operation && !waitingForOperand) {
			rightOperand = parseFloat(display);

			switch (operation) {
			case "+":
				result = leftOperand + rightOperand;
				break;
			case "-":
				result = leftOperand - rightOperand;
				break;
			case "*":
				result = leftOperand * rightOperand;
				break;
			case "/":
				if (rightOperand === 0) {
					display = "Error";
					return;
				}
				result = leftOperand / rightOperand;
				break;
			}

			display = result.toString();
			leftOperand = result;
		} else {
			leftOperand = parseFloat(display);
		}

		operation = op;
		waitingForOperand = true;
		hasDecimal = false;
	}

	function calculateResult() {
		if (operation && !waitingForOperand) {
			performOperation("");
			operation = "";
		}
	}

	property real buttonSize: (parent.width - 80) / 4

	// Display area
	Rectangle {
		id: displayArea
		width: parent.width - 10
		height: parent.width * 0.2
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.top: parent.top
		color: "#2c3e50"
		border.color: "#34495e"
		border.width: 2
		radius: height * 0.3

		Text {
			id: displayText
			anchors.centerIn: parent
			text: root.display
			font.pixelSize: Math.max(16, buttonSize * 0.4)
			font.bold: true
			color: "#ecf0f1"
			horizontalAlignment: Text.AlignRight
			elide: Text.ElideLeft
		}
	}

	// Button grid
	GridLayout {
		id: buttonGrid
		anchors.top: displayArea.bottom
		anchors.topMargin: 20
		anchors.horizontalCenter: parent.horizontalCenter
		columns: 4
		rowSpacing: buttonSize * 0.15
		columnSpacing: buttonSize * 0.15

		// Row 1: Clear, +/-, %, /
		Button {
			text: "C"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.clearAll()
			background: Rectangle {
				color: parent.pressed ? "#e74c3c" : "#c0392b"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "+/-"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: {
				if (display !== "0") {
					display = display.startsWith("-") ? display.substring(1) : "-" + display;
				}
			}
			background: Rectangle {
				color: parent.pressed ? "#95a5a6" : "#7f8c8d"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.25
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "%"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: {
				display = (parseFloat(display) / 100).toString();
			}
			background: Rectangle {
				color: parent.pressed ? "#95a5a6" : "#7f8c8d"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "÷"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.performOperation("/")
			background: Rectangle {
				color: parent.pressed ? "#f39c12" : "#e67e22"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		// Row 2: 7, 8, 9, *
		Button {
			text: "7"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.addDigit("7")
			background: Rectangle {
				color: parent.pressed ? "#34495e" : "#2c3e50"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "8"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.addDigit("8")
			background: Rectangle {
				color: parent.pressed ? "#34495e" : "#2c3e50"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "9"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.addDigit("9")
			background: Rectangle {
				color: parent.pressed ? "#34495e" : "#2c3e50"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "×"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.performOperation("*")
			background: Rectangle {
				color: parent.pressed ? "#f39c12" : "#e67e22"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		// Row 3: 4, 5, 6, -
		Button {
			text: "4"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.addDigit("4")
			background: Rectangle {
				color: parent.pressed ? "#34495e" : "#2c3e50"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "5"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.addDigit("5")
			background: Rectangle {
				color: parent.pressed ? "#34495e" : "#2c3e50"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "6"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.addDigit("6")
			background: Rectangle {
				color: parent.pressed ? "#34495e" : "#2c3e50"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "−"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.performOperation("-")
			background: Rectangle {
				color: parent.pressed ? "#f39c12" : "#e67e22"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		// Row 4: 1, 2, 3, +
		Button {
			text: "1"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.addDigit("1")
			background: Rectangle {
				color: parent.pressed ? "#34495e" : "#2c3e50"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "2"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.addDigit("2")
			background: Rectangle {
				color: parent.pressed ? "#34495e" : "#2c3e50"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "3"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.addDigit("3")
			background: Rectangle {
				color: parent.pressed ? "#34495e" : "#2c3e50"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "+"
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.performOperation("+")
			background: Rectangle {
				color: parent.pressed ? "#f39c12" : "#e67e22"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		// Row 5: 0 (wide), ., =
		Button {
			text: "0"
			Layout.preferredWidth: buttonSize * 2 + (buttonSize * 0.15)
			Layout.preferredHeight: buttonSize
			Layout.columnSpan: 2
			onClicked: root.addDigit("0")
			background: Rectangle {
				color: parent.pressed ? "#34495e" : "#2c3e50"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "."
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.addDecimal()
			background: Rectangle {
				color: parent.pressed ? "#34495e" : "#2c3e50"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}

		Button {
			text: "="
			Layout.preferredWidth: buttonSize
			Layout.preferredHeight: buttonSize
			onClicked: root.calculateResult()
			background: Rectangle {
				color: parent.pressed ? "#f39c12" : "#e67e22"
				radius: buttonSize * 0.1
			}
			contentItem: Text {
				text: parent.text
				font.pixelSize: buttonSize * 0.3
				font.bold: true
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}
		}
	}
}
