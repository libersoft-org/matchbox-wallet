import QtQuick 6.8
import QtMultimedia 6.0

Rectangle {
	id: root
	property string title: "Camera test"
	color: "#000"

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

	Component.onDestruction: {
		if (camera) {
			camera.stop();
			camera.active = false;
		}
	}
}
