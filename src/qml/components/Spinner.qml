import QtQuick 6.8
import "../static"

Item {
	id: root
	width: parent.width
	height: parent.height

	Colors {
		id: colors
	}

	// Rotating SVG icon-based spinner
	Image {
		id: spinnerIcon
		anchors.centerIn: parent
		width: parent.width
		height: width
		source: Qt.resolvedUrl('../../img/spinner.svg')
		fillMode: Image.PreserveAspectFit
		sourceSize.width: width // Render SVG at actual display size
		sourceSize.height: height // Render SVG at actual display size
		mipmap: true // Better quality for SVG scaling
		smooth: true // Smooth rendering
		antialiasing: true // Anti-aliasing for better quality

		RotationAnimation {
			id: rotation
			target: spinnerIcon
			property: 'rotation'
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
