import QtQuick 6.8
import QtQuick.Effects 6.8
import "../static"

Item {
	id: root
	width: 50
	height: 50

	Colors {
		id: colors
	}

	// Rotating SVG icon-based spinner
	Image {
		id: spinnerIcon
		anchors.centerIn: parent
		width: Math.min(parent.width, parent.height)
		height: width
		source: Qt.resolvedUrl("../../img/refresh.svg")
		fillMode: Image.PreserveAspectFit

		RotationAnimation {
			id: rotation
			target: spinnerIcon
			property: "rotation"
			from: 0
			to: 360
			duration: 1000
			loops: Animation.Infinite
			running: true
		}
	}

	Component.onCompleted: {
		rotation.start();
	}

	Component.onDestruction: {
		rotation.stop();
	}
}
