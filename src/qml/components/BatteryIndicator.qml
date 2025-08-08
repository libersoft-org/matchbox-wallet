import QtQuick 2.15

Item {
	id: root

	// Public API
	property int level: 0            // 0..100
	property bool hasBattery: false
	property var colors: undefined   // expect palette with success/error

	// Internal metrics
	property real indicatorWidth: width * 0.45
	property real tipHeight: height * 0.12
	property real bodyHeight: height - tipHeight
	property real bodyBorderWidth: Math.max(2, height * 0.08)
	property real margin: Math.max(2, Math.max(height * 0.06, bodyBorderWidth))

	// Visuals centered inside root to avoid overflow
	Column {
		id: pack
		anchors.centerIn: parent
		spacing: 0
		width: root.indicatorWidth
		height: root.height

		// Tip on top (centered over body)
		Rectangle {
			id: tip
			width: root.indicatorWidth * 0.6
			height: root.tipHeight
			color: colors.primaryForeground
			radius: Math.max(1, root.height * 0.03)
			anchors.horizontalCenter: parent.horizontalCenter
		}

		// Body below tip
		Rectangle {
			id: body
			width: root.indicatorWidth
			height: root.bodyHeight
			color: "transparent"
			border.color: colors.primaryForeground
			border.width: root.bodyBorderWidth
			radius: Math.max(1, root.height * 0.06)
			anchors.horizontalCenter: parent.horizontalCenter

			// Fill (grows from bottom up)
			Rectangle {
				id: fill
				x: root.margin
				width: body.width - 2 * root.margin
				height: (body.height - 2 * root.margin) * (Math.max(0, Math.min(100, root.level)) / 100.0)
				y: body.height - root.margin - height
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
}
