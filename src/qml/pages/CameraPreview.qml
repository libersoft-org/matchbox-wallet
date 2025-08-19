import QtQuick 2.15
import QtMultimedia 6.0

Rectangle {
	id: root
	property string title: "Camera test"

	color: "black"

	CaptureSession {
		id: captureSession
		camera: Camera {
			id: camera
			active: true
		}
		videoOutput: videoOutput
	}

	VideoOutput {
		id: videoOutput
		anchors.fill: parent
		fillMode: VideoOutput.PreserveAspectFit
	}

	Component.onCompleted: {
		camera.start();
	}
}
