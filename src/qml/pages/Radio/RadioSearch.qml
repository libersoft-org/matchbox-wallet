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

	property var searchResults: []
	property bool isSearching: false

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

			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				text: tr("radio.search.title")
				font.pixelSize: window.width * 0.06
				font.bold: true
				color: colors.primaryForeground
			}

			Rectangle {
				width: parent.width
				height: window.height * 0.06
				color: "white"
				radius: window.width * 0.01
				border.color: "#cccccc"
				border.width: 1

				TextInput {
					id: searchInput
					anchors.left: parent.left
					anchors.right: searchButton.left
					anchors.verticalCenter: parent.verticalCenter
					anchors.leftMargin: window.width * 0.03
					anchors.rightMargin: window.width * 0.02
					font.pixelSize: window.width * 0.04
					color: "#333333"

					Text {
						anchors.left: parent.left
						anchors.verticalCenter: parent.verticalCenter
						text: tr("radio.search.placeholder")
						color: "#999999"
						font.pixelSize: parent.font.pixelSize
						visible: searchInput.text.length === 0
					}

					onAccepted: searchStations(text)
				}

				Rectangle {
					id: searchButton
					anchors.right: parent.right
					anchors.verticalCenter: parent.verticalCenter
					anchors.rightMargin: window.width * 0.01
					width: window.width * 0.12
					height: parent.height * 0.8
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
	ListView {
		id: stationsList
		anchors.top: header.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.margins: window.width * 0.02
		spacing: window.width * 0.01
		model: searchResults

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
					window.goPage('Radio/RadioPlayer.qml', {
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
			visible: isSearching
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
			visible: !isSearching && searchResults.length === 0 && searchInput.text.length > 0
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
