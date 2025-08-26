import QtQuick 6.8
import "../../components"
import "../../static"

Item {
	id: root
	property string title: tr("radio.language.title")
	width: window.width
	height: window.height

	Colors {
		id: colors
	}

	property var languages: []
	property bool isLoading: false

	Component.onCompleted: {
		loadLanguages();
	}

	function loadLanguages() {
		isLoading = true;
		languages = [];

		var xhr = new XMLHttpRequest();
		xhr.onreadystatechange = function () {
			if (xhr.readyState === XMLHttpRequest.DONE) {
				isLoading = false;
				if (xhr.status === 200) {
					try {
						var response = JSON.parse(xhr.responseText);
						// Sort by station count
						response.sort(function (a, b) {
							return b.stationcount - a.stationcount;
						});
						languages = response || [];
						console.log("Languages loaded:", languages.length);
						// Update the Repeater model
						languageRepeater.model = languages;
					} catch (e) {
						console.error("Error parsing languages:", e);
						languages = [];
						languageRepeater.model = [];
					}
				} else {
					console.error("Loading languages failed with status:", xhr.status);
					languages = [];
					languageRepeater.model = [];
				}
			}
		};

		xhr.open("GET", "http://de1.api.radio-browser.info/json/languages?order=stationcount&reverse=true", true);
		xhr.send();
	}

	function loadStationsByLanguage(languageName) {
		window.goPage('Radio/RadioStationsList.qml', null, {
			filterType: "language",
			filterValue: languageName,
			pageTitle: "Languages"
		});
	}

	BaseMenu {
		anchors.fill: parent

		// Create buttons for each language
		Repeater {
			id: languageRepeater
			model: root.languages

			MenuButton {
				text: modelData.name || ""
				onClicked: {
					root.loadStationsByLanguage(modelData.name);
				}
			}
		}
	}

	// Loading indicator (overlay)
	Rectangle {
		anchors.centerIn: parent
		visible: root.isLoading
		width: parent.width * 0.8
		height: window.height * 0.2
		color: colors.primaryBackground

		Text {
			anchors.centerIn: parent
			text: tr("radio.player.loading")
			font.pixelSize: window.width * 0.04
			color: colors.primaryForeground
		}
	}
}
