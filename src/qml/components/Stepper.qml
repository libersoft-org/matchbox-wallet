import QtQuick 6.8
import QtQuick.Controls 6.8
import "../static"

SpinBox {
	id: stepper

	// Public properties - expose native SpinBox properties
	property alias minValue: stepper.from
	property alias maxValue: stepper.to
	property alias currentValue: stepper.value
	property bool leadingZeros: false
	property int minimumDigits: 1

	// Signals
	signal userInteraction

	// Colors object access
	Colors {
		id: colors
	}

	// Focus and modification handling
	onActiveFocusChanged: {
		if (activeFocus) {
			stepper.userInteraction();
		}
	}

	onValueModified: {
		stepper.userInteraction();
	}

	// Text formatting function
	function formatValue(value) {
		if (leadingZeros)
			return value.toString().padStart(minimumDigits, "0");
		return value.toString();
	}

	// Text formatting functions
	textFromValue: function (value) {
		return stepper.formatValue(value);
	}

	valueFromText: function (text) {
		return parseInt(text);
	}

	// Custom content item
	contentItem: TextInput {
		text: stepper.formatValue(stepper.value)
		font.pixelSize: window.height * 0.02
		font.bold: true
		color: colors.primaryForeground
		horizontalAlignment: Qt.AlignHCenter
		verticalAlignment: Qt.AlignVCenter
		readOnly: !stepper.editable
		validator: stepper.validator
		inputMethodHints: Qt.ImhFormattedNumbersOnly
	}

	// Custom background
	background: Rectangle {
		color: colors.primaryBackground
		border.color: colors.primaryForeground
		border.width: window.width * 0.002
		radius: window.width * 0.02
	}

	// Custom up indicator (arrow)
	up.indicator: Rectangle {
		x: stepper.mirrored ? 0 : parent.width - width
		height: parent.height / 2
		implicitWidth: 40
		implicitHeight: 40
		color: colors.primaryForeground
		border.color: colors.primaryForeground
		border.width: 1

		Text {
			text: "▲"
			font.pixelSize: parent.height * 0.4
			color: colors.primaryBackground
			anchors.centerIn: parent
		}
	}

	// Custom down indicator (arrow)
	down.indicator: Rectangle {
		x: stepper.mirrored ? 0 : parent.width - width
		y: parent.height / 2
		height: parent.height / 2
		implicitWidth: 40
		implicitHeight: 40
		color: colors.primaryForeground
		border.color: colors.primaryForeground
		border.width: 1

		Text {
			text: "▼"
			font.pixelSize: parent.height * 0.4
			color: colors.primaryBackground
			anchors.centerIn: parent
		}
	}
}
