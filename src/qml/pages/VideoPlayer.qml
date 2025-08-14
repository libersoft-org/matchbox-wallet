import QtQuick 2.15
import QtMultimedia 6.0

Item {
	id: root
	property string title: tr("menu.mediaPlayer.title")
	property bool showBackButton: true
	property bool showPowerButton: false

	Rectangle {
		anchors.fill: parent
		color: colors.primaryBackground

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

		Component.onCompleted: {
			mediaPlayer.source = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
			mediaPlayer.play();
		}
	}
}
