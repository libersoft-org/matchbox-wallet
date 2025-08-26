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
	ListView {
		id: stationsList
		anchors.top: header.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.margins: window.width * 0.02
		spacing: window.width * 0.01
		model: stations

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
					window.goPage('Radio/RadioPlayer.qml', null, {
						station: modelData
					});
				}
			}

			Row {
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				anchors.leftMargin: window.width * 0.02
				anchors.rightMargin: window.width * 0.02
				spacing: window.width * 0.02

				Column {
					width: parent.width - window.width * 0.04
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

					Text {
						text: modelData.tags || ""
						font.pixelSize: window.width * 0.025
						color: "#888888"
						width: parent.width
						elide: Text.ElideRight
						visible: text.length > 0
					}
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

		// No results message
		Rectangle {
			anchors.centerIn: parent
			visible: !isLoading && stations.length === 0
			width: parent.width * 0.8
			height: window.height * 0.2

			Text {
				anchors.centerIn: parent
				text: tr("radio.search.no_results")
				font.pixelSize: window.width * 0.04
				color: "#666666"
				horizontalAlignment: Text.AlignHCenter
			}
		}
	}
}
