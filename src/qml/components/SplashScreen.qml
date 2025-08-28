import QtQuick 6.4

Item {
	id: splashScreen
	anchors.fill: parent

	signal animationFinished

	// Background
	Rectangle {
		anchors.fill: parent
		color: colors.primaryBackground
	}

	// Center content container
	Item {
		id: centerContainer
		anchors.centerIn: parent
		width: parent.width * 0.6
		height: logoImage.height + titleText.height + 20

		// Bounce animation for the entire content
		SequentialAnimation {
			id: bounceAnimation
			running: true
			loops: 1

			// Initial scale down
			PropertyAnimation {
				target: centerContainer
				property: "scale"
				from: 0.1
				to: 1.2
				duration: 600
				easing.type: Easing.OutBack
				easing.overshoot: 2.0
			}

			// Scale back to normal
			PropertyAnimation {
				target: centerContainer
				property: "scale"
				from: 1.2
				to: 1.0
				duration: 400
				easing.type: Easing.OutQuart
			}

			// Small pause before finishing
			PauseAnimation {
				duration: 1000
			}

			onFinished: {
				splashScreen.animationFinished();
			}
		}

		// Logo container for animation
		Item {
			id: logoContainer
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.top: parent.top
			width: logoImage.width
			height: logoImage.height

			// Logo image
			Image {
				id: logoImage
				source: "../../img/logo.svg"
				width: window.width * 0.5
				height: window.width * 0.5
				sourceSize.width: window.width // Highier resolution for scaling
				sourceSize.height: window.width
				fillMode: Image.PreserveAspectFit
				smooth: true
				antialiasing: true
				mipmap: true
				anchors.centerIn: parent
			}
		}

		// Title text
		Text {
			id: titleText
			text: applicationName
			color: colors.primaryForeground
			font.pixelSize: window.width * 0.05
			font.weight: Font.Bold
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.top: logoContainer.bottom
			anchors.topMargin: 20
		}
	}
}
