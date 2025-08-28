import QtQuick 6.4

Item {
	id: root

	// Public API
	property int level: 0            // 0..100
	property bool hasBattery: false
	property bool charging: true     // when true, show charging animation

	// Displayed level (single visual fill); animates from current level to 100% when charging
	property real displayedLevel: level

	// Internal metrics
	property real indicatorWidth: width * 0.9
	property real tipHeight: height * 0.12
	property real bodyHeight: height - tipHeight
	property real bodyBorderWidth: Math.max(2, height * 0.08)
	property real margin: Math.max(2, Math.max(height * 0.06, bodyBorderWidth))

	// Unified color used for the charged part and the top-up animation
	property color fillColor: colors.success

	// Animate displayedLevel upwards to 100% while charging; stops and snaps back to level when not charging
	NumberAnimation on displayedLevel {
		from: root.level
		to: 100
		duration: 1600
		loops: Animation.Infinite
		running: root.hasBattery && root.charging
		easing.type: Easing.InOutQuad
	}

	onChargingChanged: {
		if (!charging)
			root.displayedLevel = root.level;
	}

	onLevelChanged: {
		if (!root.charging)
			root.displayedLevel = root.level;
	}

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

			// Pixel-perfect fill computation inside the body scope
			property int _marginPx: Math.round(root.margin)
			property real _fillAvailable: body.height - 2 * _marginPx
			property real _fillFraction: Math.max(0, Math.min(1, root.displayedLevel / 100.0))
			property int _fillHeightPx: Math.round(_fillAvailable * _fillFraction)

			// Fill (grows from bottom up)
			Rectangle {
				id: fill
				x: body._marginPx
				width: body.width - 2 * body._marginPx
				height: body._fillHeightPx
				y: body.height - body._marginPx - body._fillHeightPx
				color: root.fillColor
				radius: Math.max(1, root.height * 0.03)
				visible: root.hasBattery
			}

			// Charging icon inside the body (centered)
			Image {
				id: chargingIcon
				anchors.centerIn: parent
				visible: root.hasBattery && root.charging
				source: Qt.resolvedUrl("../../img/charging.svg")
				fillMode: Image.PreserveAspectFit
				opacity: 0.9
				width: body.width * 0.58
				height: body.height * 0.58
				z: 3
			}

			// Charging animation overlay (clipped to the current fill height)
			Item {
				id: chargeOverlay
				x: body._marginPx
				width: body.width - 2 * body._marginPx
				anchors.bottom: body.bottom
				anchors.bottomMargin: body._marginPx
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
					NumberAnimation on y {
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
					NumberAnimation on y {
						from: chargeOverlay.height * 0.5
						to: -pulse2.height
						duration: chargeOverlay.cycleMs
						loops: Animation.Infinite
						running: root.charging && chargeOverlay.visible
					}
				}
			}

			// Removed separate top-up overlay to avoid 1px seam; single fill animates via displayedLevel

			// Cross for no battery
			CrossOut {
				anchors.fill: parent
				visible: !root.hasBattery
				z: 10
			}
		}
	}
}
