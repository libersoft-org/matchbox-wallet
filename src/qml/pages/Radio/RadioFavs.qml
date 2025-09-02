import QtQuick 6.8
import "../../components"
import "../../static"

Item {
	id: root
	width: parent.width
	height: parent.height

	Colors {
		id: colors
	}

	property string title: tr('radio.favs.title')
	property var favouriteStations: []

	Component.onCompleted: {
		loadFavourites();
	}

	function loadFavourites() {
		// Load favourites from local storage
		var saved = window.settingsManager ? window.settingsManager.getSetting('radio_favourites', '[]') : '[]';
		try {
			favouriteStations = JSON.parse(saved);
			console.log('Loaded favourites count:', favouriteStations.length);
		} catch (e) {
			console.log('Error loading favourites:', e);
			favouriteStations = [];
		}
		// Update the Repeater model
		stationRepeater.model = favouriteStations;
	}

	BaseMenu {
		anchors.fill: parent

		// Show empty message if no favourites
		Frame {
			width: parent.width
			visible: favouriteStations.length === 0

			FrameText {
				anchors.centerIn: parent
				width: parent.width - parent.width * 0.1
				text: tr('radio.favs.empty')
				font.bold: true
				horizontalAlignment: Text.AlignHCenter
			}
		}

		// Create buttons for each favourite station
		Repeater {
			id: stationRepeater
			model: favouriteStations

			MenuButton {
				text: modelData.name
				onClicked: {
					console.log('Playing favourite station:', modelData.name);
					window.goPage('Radio/RadioPlayer.qml', null, {
						station: modelData
					});
				}
			}
		}
	}
}
