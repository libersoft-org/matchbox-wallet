import QtQuick 2.15

Item {
	id: root

	// Public API
	property int level: 0            // 0..100
	property bool hasBattery: false
	property var colors: undefined   // expect palette with success/error

	// Sizing is controlled by parent

	// Tip on top, body below, both fully inside the bounds of this item
	Rectangle {
		id: tip
		width: body.width * 0.6
		height: root.height * 0.12
		color: "white"
		radius: Math.max(1, root.height * 0.03)
		anchors.top: parent.top
		anchors.horizontalCenter: parent.horizontalCenter
	}

	Rectangle {
		id: body
		property real m: Math.max(1, root.height * 0.06)
		width: root.width * 0.45
		anchors.top: tip.bottom
		anchors.bottom: parent.bottom
		anchors.horizontalCenter: parent.horizontalCenter
		color: "transparent"
		border.color: "white"
		border.width: Math.max(1, root.height * 0.03)
		radius: Math.max(1, root.height * 0.06)

		// Fill (grows from bottom up)
		Rectangle {
			id: fill
			x: body.m
			width: body.width - 2 * body.m
			height: (body.height - 2 * body.m) * (Math.max(0, Math.min(100, root.level)) / 100.0)
			y: body.height - body.m - height
			color: (root.colors ? (root.level > 20 ? root.colors.success : root.colors.error) : (root.level > 20 ? "#00C853" : "#D50000"))
			radius: Math.max(1, root.height * 0.03)
			visible: root.hasBattery
		}

		// Cross for no battery
		CrossOut {
			anchors.fill: parent
			visible: !root.hasBattery
		}
	}
}
