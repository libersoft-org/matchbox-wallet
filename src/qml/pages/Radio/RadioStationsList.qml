import QtQuick 2.15
import QtQuick.Controls 2.15
import "../../components"
import "../../static"

Item {
	id: root
	width: window.width
	height: window.height

	Colors {
		id: colors
	}

	property string filterType: ""  // "country", "language", etc.
	property string filterValue: ""
	property string pageTitle: ""
	property var stations: []
	property bool isLoading: false

	Component.onCompleted: {
		console.log("RadioStationsList loaded with filterType:", filterType, "filterValue:", filterValue);
		if (filterType && filterValue) {
			loadStations();
		}
	}

	onFilterTypeChanged: {
		if (filterType && filterValue) {
			loadStations();
		}
	}

	onFilterValueChanged: {
		if (filterType && filterValue) {
			loadStations();
		}
	}

	function loadStations() {
		isLoading = true;
		stations = [];

		var xhr = new XMLHttpRequest();
		xhr.onreadystatechange = function () {
			console.log("XHR state changed:", xhr.readyState, "status:", xhr.status);
			if (xhr.readyState === XMLHttpRequest.DONE) {
				isLoading = false;
				if (xhr.status === 200) {
					try {
						console.log("Response received:", xhr.responseText.substring(0, 200));
						var response = JSON.parse(xhr.responseText);
						stations = response || [];
						console.log("Stations loaded:", stations.length);
						
						// Explicitly update the model for the Repeater
						stationsRepeater.model = stations;
					} catch (e) {
						console.error("Error parsing stations:", e);
						stations = [];
					}
				} else {
					console.error("Loading stations failed with status:", xhr.status);
					console.error("Response text:", xhr.responseText);
					stations = [];
				}
			}
		};

		var url = "";

		if (filterType === "country") {
			url = "http://de1.api.radio-browser.info/json/stations/bycountrycodeexact/" + encodeURIComponent(filterValue) + "?limit=100&hidebroken=true&order=clickcount&reverse=true";
		} else if (filterType === "language") {
			url = "http://de1.api.radio-browser.info/json/stations/bylanguageexact/" + encodeURIComponent(filterValue) + "?limit=100&hidebroken=true&order=clickcount&reverse=true";
		}

		console.log("Loading stations with URL:", url);
		console.log("Filter type:", filterType, "Filter value:", filterValue);
		xhr.open("GET", url, true);
		xhr.setRequestHeader("User-Agent", "MatchboxWallet/1.0");
		xhr.setRequestHeader("Accept", "application/json");
		xhr.send();
	}

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
			text: pageTitle || filterValue
			font.pixelSize: window.width * 0.06
			font.bold: true
			color: colors.primaryForeground
		}
	}

	// Content
	BaseMenu {
		id: stationsMenu
		anchors.top: header.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.margins: window.width * 0.02

		Repeater {
			id: stationsRepeater
			model: stations
			delegate: MenuButton {
				text: {
					var stationText = modelData.name || "";
					var details = [];
					if (modelData.country) details.push(modelData.country);
					if (modelData.language) details.push(modelData.language);
					if (modelData.tags) details.push(modelData.tags);
					if (details.length > 0) {
						stationText += " (" + details.join(" • ") + ")";
					}
					return stationText;
				}
				onClicked: {
					window.goPage('Radio/RadioPlayer.qml', null, {
						station: modelData
					});
				}
			}
		}
	}

	// Loading indicator (outside BaseMenu to avoid anchor conflicts)
	Rectangle {
		anchors.centerIn: parent
		visible: isLoading
		width: parent.width * 0.8
		height: window.height * 0.2
		color: "#4A4A4A"
		radius: window.width * 0.02

		Text {
			anchors.centerIn: parent
			text: tr("radio.player.loading")
			font.pixelSize: window.width * 0.04
			color: "#FFFFFF"
		}
	}

	// No results message
	Rectangle {
		anchors.centerIn: parent
		visible: !isLoading && stations.length === 0
		width: parent.width * 0.8
		height: window.height * 0.2
		color: "#4A4A4A"
		radius: window.width * 0.02

		Text {
			anchors.centerIn: parent
			text: tr("radio.search.no_results")
			font.pixelSize: window.width * 0.04
			color: "#FFFFFF"
			horizontalAlignment: Text.AlignHCenter
		}
	}
}
