import QtQuick 6.8
import QtQuick.Controls 6.8
import QtMultimedia 6.8
import "../../components"
import "../../static"

Rectangle {
	id: root
	width: parent.width
	height: parent.height
	color: colors.primaryBackground

	Colors {
		id: colors
	}

	property var station: null
	property bool isPlaying: false
	property bool isLoading: false
	property bool isFavourite: false
	property var favouriteStations: []

	MediaPlayer {
		id: mediaPlayer
		audioOutput: AudioOutput {
			id: audioOutput
			volume: 1.0
		}

		onPlaybackStateChanged: {
			console.log("MediaPlayer state changed to:", playbackState);
			if (playbackState === MediaPlayer.PlayingState) {
				isPlaying = true;
				isLoading = false;
				console.log("MediaPlayer is now playing");
			} else if (playbackState === MediaPlayer.StoppedState) {
				isPlaying = false;
				isLoading = false;
				console.log("MediaPlayer is stopped");
			}
		}

		onErrorOccurred: function (error, errorString) {
			console.log("Media player error:", error, errorString);
			isPlaying = false;
			isLoading = false;
		}

		onMediaStatusChanged: {
			console.log("Media status changed to:", mediaStatus);
		}
	}

	Component.onCompleted: {
		console.log("RadioPlayer loaded with station:", station ? station.name : "null");
		loadFavourites();
		if (station) {
			checkIfFavourite();
		}
	}

	Component.onDestruction: {
		console.log("RadioPlayer being destroyed, stopping radio playback");
		if (mediaPlayer) {
			if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
				console.log("Force stopping MediaPlayer");
				mediaPlayer.stop();
			}
			// Clear the source to free resources
			mediaPlayer.source = "";
		}
		isPlaying = false;
		isLoading = false;
	}

	function loadFavourites() {
		var saved = window.settingsManager ? window.settingsManager.getSetting("radio_favourites", "[]") : "[]";
		try {
			favouriteStations = JSON.parse(saved);
		} catch (e) {
			favouriteStations = [];
		}
	}

	function saveFavourites() {
		if (window.settingsManager) {
			console.log("Saving favourites to settings, count:", favouriteStations.length);
			var favData = JSON.stringify(favouriteStations);
			console.log("Favourites data to save:", favData.substring(0, 200) + (favData.length > 200 ? "..." : ""));
			window.settingsManager.setSetting("radio_favourites", favData);
		} else {
			console.log("ERROR: settingsManager not available for saving favourites");
		}
	}

	function checkIfFavourite() {
		if (!station)
			return;
		isFavourite = favouriteStations.some(function (fav) {
			return fav.stationuuid === station.stationuuid;
		});
	}

	function toggleFavourite() {
		if (!station) {
			console.log("toggleFavourite called but no station provided");
			return;
		}

		console.log("Toggling favourite for station:", station.name, "Currently favourite:", isFavourite);

		if (isFavourite) {
			// Remove from favourites
			console.log("Removing from favourites, current list length:", favouriteStations.length);
			for (var i = 0; i < favouriteStations.length; i++) {
				if (favouriteStations[i].stationuuid === station.stationuuid) {
					favouriteStations.splice(i, 1);
					console.log("Removed station from favourites, new length:", favouriteStations.length);
					break;
				}
			}
			isFavourite = false;
		} else {
			// Add to favourites
			console.log("Adding to favourites, current list length:", favouriteStations.length);
			favouriteStations.push(station);
			console.log("Added station to favourites, new length:", favouriteStations.length);
			isFavourite = true;
		}
		saveFavourites();
	}

	function playStation() {
		if (!station) {
			console.log("PlayStation called but no station provided");
			return;
		}

		console.log("Starting station playback:", station.name);
		isLoading = true;

		// Register click with radio-browser API
		var xhr = new XMLHttpRequest();
		xhr.onreadystatechange = function () {
			if (xhr.readyState === XMLHttpRequest.DONE) {
				console.log("Click registration completed with status:", xhr.status);
				// Play the stream regardless of click registration result
				var streamUrl = station.url_resolved || station.url;
				console.log("Playing stream:", streamUrl);
				mediaPlayer.source = streamUrl;
				mediaPlayer.play();
			}
		};

		// Register the click (but don't wait for response)
		var clickUrl = "http://de1.api.radio-browser.info/json/url/" + station.stationuuid;
		console.log("Registering click at:", clickUrl);
		xhr.open("GET", clickUrl, true);
		xhr.send();
	}

	function stopStation() {
		console.log("Stopping station playback");
		mediaPlayer.stop();
		isPlaying = false;
		isLoading = false;
	}

	// Header with station info
	Rectangle {
		id: header
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		height: window.height * 0.3
		color: colors.primaryBackground

		Column {
			anchors.centerIn: parent
			width: parent.width * 0.9
			spacing: window.width * 0.03

			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				text: window.tr("radio.player.title")
				font.pixelSize: window.width * 0.05
				font.bold: true
				color: colors.primaryForeground
			}

			Rectangle {
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width
				height: window.height * 0.15
				color: "#f0f0f0"
				radius: window.width * 0.02
				border.color: "#cccccc"
				border.width: 1

				Column {
					anchors.centerIn: parent
					width: parent.width * 0.9
					spacing: window.width * 0.01

					Text {
						text: station ? (station.name || "") : ""
						font.pixelSize: window.width * 0.05
						font.bold: true
						color: "#333333"
						width: parent.width
						elide: Text.ElideRight
						horizontalAlignment: Text.AlignHCenter
					}

					Text {
						text: station ? ((station.country || "") + (station.country && station.language ? " • " : "") + (station.language || "")) : ""
						font.pixelSize: window.width * 0.035
						color: "#666666"
						width: parent.width
						elide: Text.ElideRight
						horizontalAlignment: Text.AlignHCenter
					}

					Text {
						text: station ? (station.tags || "") : ""
						font.pixelSize: window.width * 0.03
						color: "#888888"
						width: parent.width
						elide: Text.ElideRight
						horizontalAlignment: Text.AlignHCenter
						visible: text.length > 0
					}
				}
			}
		}
	}

	// Controls
	Rectangle {
		id: controls
		anchors.top: header.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		color: colors.primaryBackground

		Column {
			anchors.centerIn: parent
			spacing: window.width * 0.05

			// Play/Stop button
			Icon {
				anchors.horizontalCenter: parent.horizontalCenter
				width: window.width * 0.2
				height: window.width * 0.2
				img: {
					if (isLoading) {
						return Qt.resolvedUrl("../../../img/refresh.svg");
					} else if (isPlaying) {
						return Qt.resolvedUrl("../../../img/stop.svg");
					} else {
						return Qt.resolvedUrl("../../../img/play.svg");
					}
				}
				onClicked: {
					if (isPlaying) {
						stopStation();
					} else {
						playStation();
					}
				}
			}

			// Favourite button
			Rectangle {
				anchors.horizontalCenter: parent.horizontalCenter
				width: window.width * 0.6
				height: window.height * 0.08
				color: isFavourite ? colors.error : colors.success
				radius: window.width * 0.02
				border.color: "#ffffff"
				border.width: 2

				Text {
					anchors.centerIn: parent
					text: isFavourite ? window.tr("radio.player.favs_del") : window.tr("radio.player.favs_add")
					font.pixelSize: window.width * 0.04
					font.bold: true
					color: "white"
				}

				MouseArea {
					anchors.fill: parent
					onClicked: toggleFavourite()
				}
			}
		}
	}
}
