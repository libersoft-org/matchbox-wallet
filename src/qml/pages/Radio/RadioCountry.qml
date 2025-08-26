import QtQuick 6.8
import "../../components"
import "../../static"

Item {
	id: root
	property string title: tr("radio.country.title")
	property var countries: []
	property bool isLoading: false
	width: window.width
	height: window.height

	Colors {
		id: colors
	}

	Component.onCompleted: {
		loadCountries();
	}

	function loadCountries() {
		isLoading = true;
		countries = [];
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
						countries = response || [];
						console.log("Countries loaded:", countries.length);
						// Update the Repeater model
						countryRepeater.model = countries;
					} catch (e) {
						console.error("Error parsing countries:", e);
						countries = [];
						countryRepeater.model = [];
					}
				} else {
					console.error("Loading countries failed with status:", xhr.status);
					countries = [];
					countryRepeater.model = [];
				}
			}
		};
		xhr.open("GET", "http://de1.api.radio-browser.info/json/countries?order=stationcount&reverse=true", true);
		xhr.send();
	}

	function loadStationsByCountry(countryCode) {
		window.goPage('Radio/RadioStationsList.qml', null, {
			filterType: "country",
			filterValue: countryCode,
			pageTitle: "Countries"
		});
	}

	BaseMenu {
		anchors.fill: parent

		// Create buttons for each country
		Repeater {
			id: countryRepeater
			model: root.countries

			MenuButton {
				text: modelData.name || ""
				onClicked: {
					root.loadStationsByCountry(modelData.iso_3166_1);
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
