import QtQuick 6.8
import "../../static"

Rectangle {
	id: root
	width: parent.width
	height: parent.height
	color: colors.primaryBackground

	Colors {
		id: colors
	}

	property var favouriteStations: []

	// Header
	Rectangle {
		id: header
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		height: window.height * 0.1
		color: colors.primaryBackground

		Text {
			anchors.centerIn: parent
			text: tr("radio.favourites.title")
			font.pixelSize: window.width * 0.06
			font.bold: true
			color: colors.primaryForeground
		}
	}

	Component.onCompleted: {
		loadFavourites();
	}

	function loadFavourites() {
		// Load favourites from local storage
		var saved = window.settingsManager ? window.settingsManager.getSetting("radio_favourites", "[]") : "[]";
		try {
			favouriteStations = JSON.parse(saved);
		} catch (e) {
			favouriteStations = [];
		}
		stationsList.model = favouriteStations;
	}

	function saveFavourites() {
		if (window.settingsManager) {
			window.settingsManager.setSetting("radio_favourites", JSON.stringify(favouriteStations));
		}
	}

	function removeFavourite(stationUuid) {
		for (var i = 0; i < favouriteStations.length; i++) {
			if (favouriteStations[i].stationuuid === stationUuid) {
				favouriteStations.splice(i, 1);
				break;
			}
		}
		stationsList.model = favouriteStations;
		saveFavourites();
	}

	ListView {
		id: stationsList
		anchors.fill: parent
		anchors.margins: window.width * 0.02
		spacing: window.width * 0.01

		delegate: Rectangle {
			width: stationsList.width
			height: window.height * 0.12
			color: "#f0f0f0"
			radius: window.width * 0.01
			border.color: "#cccccc"
			border.width: 1

			MouseArea {
				anchors.fill: parent
				onClicked: {
					console.log("Playing favourite station:", modelData.name);
					window.goPage('Radio/RadioPlayer.qml', null, {
						station: modelData
					});
				}
			}

			Row {
				anchors.left: parent.left
				anchors.right: removeButton.left
				anchors.verticalCenter: parent.verticalCenter
				anchors.leftMargin: window.width * 0.02
				anchors.rightMargin: window.width * 0.02
				spacing: window.width * 0.02

				Column {
					width: parent.width
					anchors.verticalCenter: parent.verticalCenter

					Text {
						text: modelData.name || ""
						font.pixelSize: window.width * 0.04
						font.bold: true
						color: "#333333"
						width: parent.width
						elide: Text.ElideRight
					}

					Text {
						text: (modelData.country || "") + (modelData.country && modelData.language ? " • " : "") + (modelData.language || "")
						font.pixelSize: window.width * 0.03
						color: "#666666"
						width: parent.width
						elide: Text.ElideRight
					}
				}
			}

			Rectangle {
				id: removeButton
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				anchors.rightMargin: window.width * 0.02
				width: window.width * 0.08
				height: window.width * 0.08
				color: "#ff4444"
				radius: width / 2

				Text {
					anchors.centerIn: parent
					text: "×"
					font.pixelSize: window.width * 0.05
					font.bold: true
					color: "white"
				}

				MouseArea {
					anchors.fill: parent
					onClicked: {
						removeFavourite(modelData.stationuuid);
					}
				}
			}
		}

		Rectangle {
			anchors.centerIn: parent
			visible: favouriteStations.length === 0
			width: parent.width * 0.8
			height: window.height * 0.2

			Text {
				anchors.centerIn: parent
				text: tr("radio.favourites.empty")
				font.pixelSize: window.width * 0.04
				color: "#666666"
				horizontalAlignment: Text.AlignHCenter
			}
		}
	}
}
