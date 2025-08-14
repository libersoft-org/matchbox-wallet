import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtMultimedia 6.0
import "../components"

Item {
	id: root
	property string title: tr("menu.mediaPlayer.title")
	property bool showBackButton: true
	property bool showPowerButton: false
	property bool isVideoFullscreen: false
	property bool isRotated: false  // true = 90° rotation, false = 0°
	property bool controlsVisible: true
	signal fullscreenRequested(bool fullscreen)

	Rectangle {
		anchors.fill: parent
		color: "#000"
	}

	Item {
		id: contentWrapper
		anchors.centerIn: parent
		width: root.isRotated ? parent.height : parent.width
		height: root.isRotated ? parent.width : parent.height

		transform: Rotation {
			origin.x: contentWrapper.width / 2
			origin.y: contentWrapper.height / 2
			angle: root.isRotated ? 90 : 0
		}

		MediaPlayer {
			id: mediaPlayer
			audioOutput: AudioOutput {}
		}

		VideoOutput {
			id: videoOutput
			anchors.fill: root.isVideoFullscreen ? root : parent
			z: root.isVideoFullscreen ? 999 : 0

			Component.onCompleted: {
				mediaPlayer.videoOutput = videoOutput;
			}

			MouseArea {
				anchors.fill: parent
				onClicked: {
					root.controlsVisible = !root.controlsVisible;
					hideTimer.restart();
				}
			}
		}

		// Control panel at the bottom
		Rectangle {
			id: controlPanel
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: window.width * 0.3
			color: "#AA000000"
			z: root.isVideoFullscreen ? 1000 : 1
			visible: root.controlsVisible

			Column {
				anchors.fill: parent
				anchors.margins: 10
				spacing: parent.height * 0.1

				// Seek bar
				Rectangle {
					width: parent.width
					height: parent.height * 0.5
					color: Qt.lighter(colors.primaryBackground)
					radius: height * 0.5
					clip: true

					Rectangle {
						width: (mediaPlayer.duration > 0) ? (parent.width * mediaPlayer.position / mediaPlayer.duration) : 0
						height: parent.height
						color: colors.primaryForeground
					}

					MouseArea {
						anchors.fill: parent
						onClicked: {
							if (mediaPlayer.duration > 0) {
								var newPosition = (mouse.x / width) * mediaPlayer.duration;
								mediaPlayer.setPosition(newPosition);
							}
							root.controlsVisible = true;
							hideTimer.restart();
						}
					}

					Text {
						anchors.left: parent.left
						anchors.leftMargin: parent.width * 0.02
						anchors.verticalCenter: parent.verticalCenter
						text: formatTime(mediaPlayer.position)
						font.bold: true
						color: colors.primaryForeground
						font.pixelSize: parent.height * 0.8
					}

					Text {
						anchors.right: parent.right
						anchors.rightMargin: parent.width * 0.02
						anchors.verticalCenter: parent.verticalCenter
						text: formatTime(mediaPlayer.duration)
						font.bold: true
						color: colors.primaryForeground
						font.pixelSize: parent.height * 0.8
					}
				}

				// Control buttons
				Item {
					width: parent.width
					height: window.width * 0.1

					// Left side buttons
					Row {
						anchors.left: parent.left
						spacing: parent.width * 0.05

						// Play/Pause button
						Icon {
							width: window.width * 0.1
							height: window.width * 0.1
							img: (mediaPlayer.playbackState === MediaPlayer.PlayingState) ? "qrc:/WalletModule/src/img/pause.svg" : "qrc:/WalletModule/src/img/play.svg"

							MouseArea {
								anchors.fill: parent
								onClicked: {
									if (mediaPlayer.playbackState === MediaPlayer.PlayingState)
										mediaPlayer.pause();
									else
										mediaPlayer.play();
									root.controlsVisible = true;
									hideTimer.restart();
								}
							}
						}

						// Stop button
						Icon {
							width: window.width * 0.1
							height: window.width * 0.1
							img: "qrc:/WalletModule/src/img/stop.svg"

							MouseArea {
								anchors.fill: parent
								onClicked: {
									mediaPlayer.stop();
									root.controlsVisible = true;
									hideTimer.restart();
								}
							}
						}
					}

					// Right side buttons
					Row {
						anchors.right: parent.right
						spacing: parent.width * 0.05

						// Rotate button
						Icon {
							width: window.width * 0.1
							height: window.width * 0.1
							img: "qrc:/WalletModule/src/img/rotate.svg"

							MouseArea {
								anchors.fill: parent
								onClicked: {
									root.isRotated = !root.isRotated;
									root.controlsVisible = true;
									hideTimer.restart();
								}
							}
						}

						// Fullscreen button
						Icon {
							width: window.width * 0.1
							height: window.width * 0.1
							img: "qrc:/WalletModule/src/img/max.svg"

							MouseArea {
								anchors.fill: parent
								onClicked: {
									root.isVideoFullscreen = !root.isVideoFullscreen;
									root.fullscreenRequested(root.isVideoFullscreen);
									root.controlsVisible = true;
									hideTimer.restart();
								}
							}
						}
					}
				}
			}
		}
	}

	// Auto-hide timer for controls
	Timer {
		id: hideTimer
		interval: 3000  // 3 seconds
		repeat: false
		onTriggered: root.controlsVisible = false
	}

	function formatTime(milliseconds) {
		var totalSeconds = Math.floor(milliseconds / 1000);
		var minutes = Math.floor(totalSeconds / 60);
		var seconds = totalSeconds % 60;
		return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
	}

	Component.onCompleted: {
		mediaPlayer.source = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
		mediaPlayer.play();
		hideTimer.start();
	}
}
