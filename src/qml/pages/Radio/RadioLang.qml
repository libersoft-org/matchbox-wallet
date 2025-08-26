import QtQuick 6.8
import "../../static"

Rectangle {
	id: root
	property string title: tr("radio.language.title")
	width: parent.width
	height: parent.height
	color: colors.primaryBackground

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
					} catch (e) {
						console.error("Error parsing languages:", e);
						languages = [];
					}
				} else {
					console.error("Loading languages failed with status:", xhr.status);
					languages = [];
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

	// Content
	ListView {
		id: languagesList
		anchors.top: header.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.margins: window.width * 0.02
		spacing: window.width * 0.01
		model: languages

		delegate: Rectangle {
			width: languagesList.width
			height: window.height * 0.08
			color: "#f0f0f0"
			radius: window.width * 0.01
			border.color: "#cccccc"
			border.width: 1

			MouseArea {
				anchors.fill: parent
				onClicked: {
					loadStationsByLanguage(modelData.name);
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
