import QtQuick 2.15
import QtQuick.Controls 2.15
import QtMultimedia 6.0

Item {
	id: root
	property string title: tr("menu.mediaPlayer.title")
	property bool showBackButton: true
	property bool showPowerButton: false

	Rectangle {
		anchors.fill: parent
		color: "#000000"

		MediaPlayer {
			id: mediaPlayer
			audioOutput: AudioOutput {}
		}

		VideoOutput {
			id: videoOutput
			anchors.fill: parent

			Component.onCompleted: {
				mediaPlayer.videoOutput = videoOutput
			}
		}

		// Ovládací panel dole
		Rectangle {
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			height: 100
			color: "#AA000000" // Semi-transparent black
			
			Column {
				anchors.fill: parent
				anchors.margins: 10
				spacing: 10

				// Seek bar
				Rectangle {
					width: parent.width
					height: 30
					color: "#333333"
					radius: 15

					Rectangle {
						width: (mediaPlayer.duration > 0) ? (parent.width * mediaPlayer.position / mediaPlayer.duration) : 0
						height: parent.height
						color: "#FF6600"
						radius: 15
					}

					MouseArea {
						anchors.fill: parent
						onClicked: {
							if (mediaPlayer.duration > 0) {
								var newPosition = (mouse.x / width) * mediaPlayer.duration
								mediaPlayer.setPosition(newPosition)
							}
						}
					}

					Text {
						anchors.left: parent.left
						anchors.leftMargin: 10
						anchors.verticalCenter: parent.verticalCenter
						text: formatTime(mediaPlayer.position)
						color: "white"
						font.pixelSize: 12
					}

					Text {
						anchors.right: parent.right
						anchors.rightMargin: 10
						anchors.verticalCenter: parent.verticalCenter
						text: formatTime(mediaPlayer.duration)
						color: "white"
						font.pixelSize: 12
					}
				}

				// Ovládací tlačítka
				Row {
					anchors.horizontalCenter: parent.horizontalCenter
					spacing: 20

					// Stop tlačítko
					Rectangle {
						width: 50
						height: 50
						color: "#555555"
						radius: 25

						Text {
							anchors.centerIn: parent
							text: "⏹"
							color: "white"
							font.pixelSize: 20
						}

						MouseArea {
							anchors.fill: parent
							onClicked: {
								mediaPlayer.stop()
							}
						}
					}

					// Play/Pause tlačítko
					Rectangle {
						width: 60
						height: 60
						color: "#FF6600"
						radius: 30

						Text {
							anchors.centerIn: parent
							text: (mediaPlayer.playbackState === MediaPlayer.PlayingState) ? "⏸" : "▶"
							color: "white"
							font.pixelSize: 24
						}

						MouseArea {
							anchors.fill: parent
							onClicked: {
								if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
									mediaPlayer.pause()
								} else {
									mediaPlayer.play()
								}
							}
						}
					}
				}
			}
		}

		Component.onCompleted: {
			mediaPlayer.source = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
			mediaPlayer.play()
		}
	}

	function formatTime(milliseconds) {
		var totalSeconds = Math.floor(milliseconds / 1000)
		var minutes = Math.floor(totalSeconds / 60)
		var seconds = totalSeconds % 60
		return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
	}
}
