import QtQuick 6.8
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

	Component.onCompleted: {
		Qt.callLater(function () {
			searchInput.forceActiveFocus();
		});
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
		var url = "http://de1.api.radio-browser.info/json/stations/byname/" + encodedQuery + "?limit=200";
		xhr.open("GET", url, true);
		xhr.send();
	}

	Column {
		anchors.horizontalCenter: parent.horizontalCenter
		width: parent.width * 0.9
		spacing: window.width * 0.02
		visible: !isSearching

		Input {
			id: searchInput
			width: parent.width
			inputHeight: window.height * 0.06
			inputPlaceholder: tr("radio.search.placeholder")
			onInputReturnPressed: searchStations(text)
		}

		MenuButton {
			text: tr("radio.search.button")
			onClicked: searchStations(searchInput.text)
		}
	}

	// Loading indicator
	Spinner {
		anchors.centerIn: parent
		visible: isSearching
		width: window.width * 0.5
		height: width
	}

	// Search results
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

	// No results
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
