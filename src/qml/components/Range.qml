import QtQuick 2.15
import QtQuick.Controls 2.15
import "../static"

Item {
	id: root
	property real value: 0
	property real from: 0
	property real to: 100
	property real stepSize: 1
	property string suffix: "%"
	property bool enabled: true
	signal rangeValueChanged(real value)
	height: 80

	Rectangle {
		id: background
		anchors.fill: parent
		color: "transparent"
		border.color: colors.disabledForeground
		border.width: 2
		radius: 8
		opacity: root.enabled ? 1.0 : 0.5
	}

	Column {
		anchors.centerIn: parent
		spacing: 10
		width: parent.width - 40

		Text {
			id: valueLabel
			anchors.horizontalCenter: parent.horizontalCenter
			text: Math.round(root.value) + root.suffix
			font.pixelSize: 24
			font.bold: true
			color: colors.primaryForeground
		}

		Rectangle {
			id: sliderTrack
			width: parent.width
			height: 6
			color: colors.disabledForeground
			radius: 3

			Rectangle {
				id: sliderFill
				width: (root.value - root.from) / (root.to - root.from) * parent.width
				height: parent.height
				color: colors.primaryForeground
				radius: 3
			}

			Rectangle {
				id: sliderHandle
				width: 24
				height: 24
				radius: 12
				color: colors.primaryForeground
				border.color: colors.disabledForeground
				border.width: 2
				x: Math.max(0, Math.min(parent.width - width, (root.value - root.from) / (root.to - root.from) * parent.width - width / 2))
				y: (parent.height - height) / 2

				MouseArea {
					id: mouseArea
					anchors.fill: parent
					anchors.margins: -10
					enabled: root.enabled
					property bool dragging: false
					property real pendingValue: root.value

					onPressed: {
						dragging = true;
						pendingValue = root.value;
					}

					onReleased: {
						dragging = false;
						// Only emit the signal when mouse is released
						if (pendingValue !== root.value)
							root.rangeValueChanged(root.value);
					}

					onPositionChanged: {
						if (dragging) {
							var newX = Math.max(0, Math.min(sliderTrack.width, mouseX + sliderHandle.x));
							var newValue = root.from + (newX / sliderTrack.width) * (root.to - root.from);
							// Snap to step size
							newValue = Math.round(newValue / root.stepSize) * root.stepSize;
							newValue = Math.max(root.from, Math.min(root.to, newValue));
							// Update visual value but don't emit signal yet
							if (newValue !== root.value)
								root.value = newValue;
						}
					}
				}
			}
		}
	}
}
