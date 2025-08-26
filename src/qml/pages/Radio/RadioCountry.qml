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

	property var countries: []
	property bool isLoading: false

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
					} catch (e) {
						console.error("Error parsing countries:", e);
						countries = [];
					}
				} else {
					console.error("Loading countries failed with status:", xhr.status);
					countries = [];
				}
			}
		};

		xhr.open("GET", "http://de1.api.radio-browser.info/json/countries?order=stationcount&reverse=true", true);
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
			text: tr("radio.country.title")
			font.pixelSize: window.width * 0.06
			font.bold: true
			color: colors.primaryForeground
		}
	}

	function loadStationsByCountry(countryCode) {
		window.goPage('Radio/RadioStationsList.qml', null, {
			filterType: "country",
			filterValue: countryCode,
			pageTitle: "Countries"
		});
	}

	// Content
	ListView {
		id: countriesList
		anchors.top: header.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.margins: window.width * 0.02
		spacing: window.width * 0.01
		model: countries

		delegate: Rectangle {
			width: countriesList.width
			height: window.height * 0.08
			color: "#f0f0f0"
			radius: window.width * 0.01
			border.color: "#cccccc"
			border.width: 1

			MouseArea {
				anchors.fill: parent
				onClicked: {
					loadStationsByCountry(modelData.iso_3166_1);
				}
			}

			Row {
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				anchors.leftMargin: window.width * 0.03
				anchors.rightMargin: window.width * 0.03
				spacing: window.width * 0.02

				Text {
					text: modelData.name || ""
					font.pixelSize: window.width * 0.04
					font.bold: true
					color: "#333333"
					width: parent.width * 0.7
					elide: Text.ElideRight
					anchors.verticalCenter: parent.verticalCenter
				}

				Text {
					text: (modelData.stationcount || "0") + " stations"
					font.pixelSize: window.width * 0.03
					color: "#666666"
					anchors.verticalCenter: parent.verticalCenter
				}
			}
		}

		// Loading indicator
		Rectangle {
			anchors.centerIn: parent
			visible: isLoading
			width: parent.width * 0.8
			height: window.height * 0.2

			Text {
				anchors.centerIn: parent
				text: tr("radio.player.loading")
				font.pixelSize: window.width * 0.04
				color: colors.primaryForeground
			}
		}
	}
}
