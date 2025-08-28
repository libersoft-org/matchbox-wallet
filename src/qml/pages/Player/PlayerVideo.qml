import QtQuick 6.4
import QtQuick.Window 6.4
import QtMultimedia 6.0
import "../../components"

Item {
	id: root
	property var playlist: []
	property int currentIndex: 0
	property string sourceUrl: {
		if (playlist.length > 0 && currentIndex >= 0 && currentIndex < playlist.length)
			return playlist[currentIndex];
		return root.singleSourceUrl || "";
	}
	property string singleSourceUrl: "" // For single file playback
	property string title: sourceUrl ? sourceUrl.substring(sourceUrl.lastIndexOf("/") + 1) : ""
	property bool isVideoFullscreen: false
	property bool isRotated: false  // true = 90° rotation, false = 0°
	property bool controlsVisible: true

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
			onMediaStatusChanged: {
				console.log("Media status changed:", mediaStatus);
				if (mediaStatus === MediaPlayer.EndOfMedia && root.playlist.length > 1)
					root.playNext();
			}
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
					id: seekBarContainer
					width: parent.width
					height: parent.height * 0.5
					radius: height * 0.5

					gradient: Gradient {
						orientation: Gradient.Horizontal

						GradientStop {
							position: 0.0
							color: colors.primaryForeground
						}

						GradientStop {
							position: (mediaPlayer.duration > 0) ? (mediaPlayer.position / mediaPlayer.duration) : 0.0
							color: colors.primaryForeground
						}

						GradientStop {
							position: (mediaPlayer.duration > 0) ? ((mediaPlayer.position / mediaPlayer.duration) + 0.001) : 0.001
							color: Qt.lighter(colors.primaryBackground)
						}

						GradientStop {
							position: 1.0
							color: Qt.lighter(colors.primaryBackground)
						}
					}

					MouseArea {
						anchors.fill: parent
						onClicked: function (mouse) {
							if (mediaPlayer.duration > 0) {
								var newPosition = (mouse.x / width) * mediaPlayer.duration;
								mediaPlayer.setPosition(newPosition);
							}
							root.controlsVisible = true;
							hideTimer.restart();
						}
					}

					// Left time text - base text
					Text {
						anchors.left: parent.left
						anchors.leftMargin: parent.width * 0.02
						anchors.verticalCenter: parent.verticalCenter
						text: formatTime(mediaPlayer.position)
						font.bold: true
						color: colors.primaryForeground
						font.pixelSize: parent.height * 0.6
					}

					// Left time text - overlaid inverted text (clipped by progress)
					Text {
						anchors.left: parent.left
						anchors.leftMargin: parent.width * 0.02
						anchors.verticalCenter: parent.verticalCenter
						text: formatTime(mediaPlayer.position)
						font.bold: true
						color: colors.primaryBackground
						font.pixelSize: parent.height * 0.6
						width: Math.max(0, (parent.width * (mediaPlayer.duration > 0 ? mediaPlayer.position / mediaPlayer.duration : 0)) - anchors.leftMargin)
						clip: true
					}

					// Right time text - base text
					Text {
						anchors.right: parent.right
						anchors.rightMargin: parent.width * 0.02
						anchors.verticalCenter: parent.verticalCenter
						text: formatTime(mediaPlayer.duration)
						font.bold: true
						color: colors.primaryForeground
						font.pixelSize: parent.height * 0.6
					}

					// Right time text - overlaid inverted text (clipped by progress)
					Text {
						anchors.verticalCenter: parent.verticalCenter
						text: formatTime(mediaPlayer.duration)
						font.bold: true
						color: colors.primaryBackground
						font.pixelSize: parent.height * 0.6

						// Same position as base text, but clipped
						x: parent.width - (parent.width * 0.02) - implicitWidth
						width: Math.max(0, (parent.width * (mediaPlayer.duration > 0 ? mediaPlayer.position / mediaPlayer.duration : 0)) - x)
						clip: true
					}
				}

				// Control buttons
				Item {
					width: parent.width
					height: window.width * 0.1

					// Left side buttons
					Row {
						anchors.left: parent.left
						spacing: parent.width * 0.03

						// Previous button
						Icon {
							width: window.width * 0.1
							height: window.width * 0.1
							img: "qrc:/WalletModule/src/img/previous.svg"
							opacity: (root.playlist.length > 1 && root.currentIndex > 0) ? 1.0 : 0.4

							MouseArea {
								anchors.fill: parent
								enabled: root.playlist.length > 1 && root.currentIndex > 0
								onClicked: {
									root.playPrevious();
									root.controlsVisible = true;
									hideTimer.restart();
								}
							}
						}

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

						// Next button
						Icon {
							width: window.width * 0.1
							height: window.width * 0.1
							img: "qrc:/WalletModule/src/img/next.svg"
							opacity: (root.playlist.length > 1 && root.currentIndex < (root.playlist.length - 1)) ? 1.0 : 0.4

							MouseArea {
								anchors.fill: parent
								enabled: root.playlist.length > 1 && root.currentIndex < (root.playlist.length - 1)
								onClicked: {
									root.playNext();
									root.controlsVisible = true;
									hideTimer.restart();
								}
							}
						}
					}

					// Right side buttons
					Row {
						anchors.right: parent.right
						spacing: parent.width * 0.03

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
									window.isFullscreen = root.isVideoFullscreen;
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
		interval: 5000  // 5 seconds
		repeat: false
		onTriggered: root.controlsVisible = false
	}

	function formatTime(milliseconds) {
		var totalSeconds = Math.floor(milliseconds / 1000);
		var hours = Math.floor(totalSeconds / 3600);
		var minutes = Math.floor((totalSeconds % 3600) / 60);
		var seconds = totalSeconds % 60;

		if (hours > 0) {
			return hours + ":" + (minutes < 10 ? "0" : "") + minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
		} else {
			return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
		}
	}

	function playPrevious() {
		if (root.playlist.length > 1 && root.currentIndex > 0) {
			root.currentIndex--;
			loadCurrentMedia();
		}
	}

	function playNext() {
		if (root.playlist.length > 1 && root.currentIndex < (root.playlist.length - 1)) {
			root.currentIndex++;
			loadCurrentMedia();
		}
	}

	function loadCurrentMedia() {
		if (root.sourceUrl && root.sourceUrl.length > 0) {
			console.log("Loading media:", root.sourceUrl);
			mediaPlayer.source = root.sourceUrl;
			mediaPlayer.play();
		}
	}

	Component.onCompleted: {
		console.log("PlayerVideo component completed with sourceUrl:", sourceUrl);
		if (playlist.length > 0)
			console.log("PlayerVideo playlist mode with", playlist.length, "items, starting at index:", currentIndex);
		console.log("PlayerVideo component ID:", root);
		if (sourceUrl && sourceUrl.length > 0) {
			mediaPlayer.source = sourceUrl;
			mediaPlayer.play();
		}
		hideTimer.start();
	}

	Component.onDestruction: {
		console.log("PlayerVideo component ID being destroyed:", root);
		mediaPlayer.stop();
	}

	// Monitor visibility changes
	onVisibleChanged: {
		console.log("PlayerVideo visibility changed to:", visible);
		if (!visible) {
			console.log("PlayerVideo became invisible, pausing playback");
			mediaPlayer.pause();
		}
	}

	// Monitor parent changes
	onParentChanged: {
		console.log("PlayerVideo parent changed to:", parent);
	}
}
