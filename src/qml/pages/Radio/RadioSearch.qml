import QtQuick 6.4
import "../../components"
import "../../static"

Rectangle {
	id: root
	property string title: tr("radio.search.title")
	property var searchResults: []
	property bool isSearching: false
	width: parent.width
	height: parent.height
	color: colors.primaryBackground

	Colors {
		id: colors
	}

	function searchStations(query) {
		if (query.trim() === "") {
			searchResults = [];
			return;
		}
		isSearching = true;
		searchResults = [];
		var xhr = new XMLHttpRequest();
		xhr.onreadystatechange = function () {
			if (xhr.readyState === XMLHttpRequest.DONE) {
				isSearching = false;
				if (xhr.status === 200) {
					try {
						var response = JSON.parse(xhr.responseText);
						searchResults = response || [];
						console.log("Search results loaded:", searchResults.length, "stations");

						// Explicitly update the model for the Repeater
						searchRepeater.model = searchResults;
					} catch (e) {
						console.error("Error parsing search results:", e);
						searchResults = [];
					}
				} else {
					console.error("Search failed with status:", xhr.status);
					searchResults = [];
				}
			}
		};

		var encodedQuery = encodeURIComponent(query);
		var url = "http://de1.api.radio-browser.info/json/stations/byname/" + encodedQuery + "?limit=50";
		xhr.open("GET", url, true);
		xhr.send();
	}

	// Header
	Rectangle {
		id: header
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		height: window.height * 0.15
		color: colors.primaryBackground

		Column {
			anchors.centerIn: parent
			width: parent.width * 0.9
			spacing: window.width * 0.02

			Row {
				width: parent.width
				spacing: window.width * 0.02

				Input {
					id: searchInput
					width: parent.width - searchButton.width - parent.spacing
					inputHeight: window.height * 0.06
					inputPlaceholder: tr("radio.search.placeholder")
					onInputReturnPressed: searchStations(text)
				}

				Rectangle {
					id: searchButton
					width: window.width * 0.12
					height: window.height * 0.06
					color: colors.primaryForeground
					radius: window.width * 0.005

					Text {
						anchors.centerIn: parent
						text: "🔍"
						font.pixelSize: window.width * 0.04
					}

					MouseArea {
						anchors.fill: parent
						onClicked: searchStations(searchInput.text)
					}
				}
			}
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
			id: searchRepeater
			model: searchResults
			delegate: MenuButton {
				text: modelData.name || ""
				onClicked: {
					window.goPage('Radio/RadioPlayer.qml', null, {
						station: modelData
					});
				}
			}
		}
	}

	// Loading indicator (outside BaseMenu to avoid anchor conflicts)
	Spinner {
		anchors.centerIn: parent
		visible: isSearching
		width: window.width * 0.15
		height: width
	}

	// No results message
	Frame {
		anchors.centerIn: parent
		visible: !isSearching && searchResults.length === 0 && searchInput.text.length > 0
		width: parent.width * 0.8

		Text {
			anchors.centerIn: parent
			text: tr("radio.search.no_results")
			font.pixelSize: window.width * 0.04
			color: colors.primaryForeground
			horizontalAlignment: Text.AlignHCenter
		}
	}
}
