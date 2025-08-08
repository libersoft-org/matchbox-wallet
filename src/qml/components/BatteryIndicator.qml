import QtQuick 2.15

Item {
	id: root

	// Public API
	property int level: 0            // 0..100
	property bool hasBattery: false
	property bool charging: true     // when true, show charging animation
	property var colors: undefined   // expect palette with success/error

	// Internal metrics
	property real indicatorWidth: width * 0.9
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

			// Charging animation overlay (clipped to the current fill height)
			Item {
				id: chargeOverlay
				x: root.margin
				width: body.width - 2 * root.margin
				anchors.bottom: body.bottom
				anchors.bottomMargin: root.margin
				height: fill.height
				clip: true
				visible: root.hasBattery && root.charging

				// animation tuning
				property real pulseHeight: Math.max(3, root.height * 0.08)
				property int cycleMs: 1200

				// Rising highlight pulse 1
				Rectangle {
					id: pulse1
					width: parent.width
					height: chargeOverlay.pulseHeight
					y: chargeOverlay.height
					radius: Math.max(1, root.height * 0.03)
					color: "transparent"
					gradient: Gradient {
						GradientStop {
							position: 0.0
							color: Qt.rgba(1, 1, 1, 0.0)
						}
						GradientStop {
							position: 0.5
							color: Qt.rgba(1, 1, 1, 0.35)
						}
						GradientStop {
							position: 1.0
							color: Qt.rgba(1, 1, 1, 0.0)
						}
					}
					NumberAnimation on y  {
						from: chargeOverlay.height
						to: -pulse1.height
						duration: chargeOverlay.cycleMs
						loops: Animation.Infinite
						running: root.charging && chargeOverlay.visible
					}
				}

				// Rising highlight pulse 2 (phase-shifted for continuous motion)
				Rectangle {
					id: pulse2
					width: parent.width
					height: chargeOverlay.pulseHeight
					y: chargeOverlay.height * 0.5
					radius: Math.max(1, root.height * 0.03)
					color: "transparent"
					gradient: Gradient {
						GradientStop {
							position: 0.0
							color: Qt.rgba(1, 1, 1, 0.0)
						}
						GradientStop {
							position: 0.5
							color: Qt.rgba(1, 1, 1, 0.25)
						}
						GradientStop {
							position: 1.0
							color: Qt.rgba(1, 1, 1, 0.0)
						}
					}
					NumberAnimation on y  {
						from: chargeOverlay.height * 0.5
						to: -pulse2.height
						duration: chargeOverlay.cycleMs
						loops: Animation.Infinite
						running: root.charging && chargeOverlay.visible
					}
				}
			}

			// Cross for no battery
			CrossOut {
				anchors.fill: parent
				visible: !root.hasBattery
			}
		}
	}
}
