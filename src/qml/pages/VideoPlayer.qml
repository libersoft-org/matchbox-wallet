import QtQuick 2.15
import QtQuick.Controls 2.15
import QtMultimedia 6.0
import "../components"

Item {
	id: root
	property string title: tr("menu.mediaPlayer.title")
	property bool showBackButton: true
	property bool showPowerButton: false

	Rectangle {
		anchors.fill: parent
		color: "#000"

		MediaPlayer {
			id: mediaPlayer
			audioOutput: AudioOutput {}
		}

		VideoOutput {
			id: videoOutput
			anchors.fill: parent

			Component.onCompleted: {
				mediaPlayer.videoOutput = videoOutput;
			}
		}

		// Control panel at the bottom
		Rectangle {
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: window.width * 0.3
			color: "#AA000000"

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
							onClicked: mediaPlayer.stop()
						}
					}
				}
			}
		}

		Component.onCompleted: {
			mediaPlayer.source = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
			mediaPlayer.play();
		}
	}

	function formatTime(milliseconds) {
		var totalSeconds = Math.floor(milliseconds / 1000);
		var minutes = Math.floor(totalSeconds / 60);
		var seconds = totalSeconds % 60;
		return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
	}
}
