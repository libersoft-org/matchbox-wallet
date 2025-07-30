import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
	id: root
	color: "#f0f0f0"
	signal backRequested
	property var availableFonts: Qt.fontFamilies()
	property var uniqueFontFamilies: {
		var families = [];
		var seen = {};
		for (var i = 0; i < availableFonts.length; i++) {
			var family = availableFonts[i];
			var baseName = family.replace(/ (Bold|Italic|Light|Medium|Thin|Black|Heavy|Regular|Normal).*$/g, "");
			if (!seen[baseName]) {
				seen[baseName] = true;
				families.push(baseName);
			}
		}
		return families.sort();
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 20
		spacing: 20

		// Header with back button and title
		RowLayout {
			Layout.fillWidth: true

			Button {
				id: backButton
				Layout.preferredWidth: 80
				Layout.preferredHeight: 40
				text: qsTr("← Back")

				background: Rectangle {
					color: backButton.pressed ? "#e0e0e0" : (backButton.hovered ? "#f0f0f0" : "#f8f9fa")
					radius: 6
					border.color: "#6c757d"
					border.width: 1
				}

				contentItem: Text {
					text: backButton.text
					font.pointSize: 10
					color: "#333333"
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
				}

				onClicked: {
					root.backRequested();
				}
			}

			Text {
				text: qsTr("Font Configuration")
				font.pointSize: 24
				font.bold: true
				color: "#333333"
				Layout.alignment: Qt.AlignHCenter
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignHCenter
			}

			// Spacer to center the title
			Item {
				Layout.preferredWidth: 80
			}
		}

		// Recommended fonts examples
		Rectangle {
			Layout.fillWidth: true
			Layout.fillHeight: true
			color: "white"
			border.color: "#cccccc"
			border.width: 1
			radius: 8

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: 20
				spacing: 10

				Text {
					text: qsTr("Current: Droid Sans | Available alternatives:")
					font.bold: true
					color: "#333333"
				}

				ScrollView {
					Layout.fillWidth: true
					Layout.fillHeight: true

					Column {
						spacing: 15
						width: parent.parent.width

						Rectangle {
							width: parent.width
							height: 80
							color: "#f8f9fa"
							border.color: "#dee2e6"
							border.width: 1
							radius: 4

							ColumnLayout {
								anchors.fill: parent
								anchors.margins: 15
								spacing: 8

								Text {
									text: "DejaVu Sans"
									font.family: "DejaVu Sans"
									font.pointSize: 16
									font.bold: true
									color: "#333333"
									Layout.fillWidth: true
								}

								Text {
									text: qsTr("Sample: Ahoj světe! The quick brown fox jumps over the lazy dog.")
									font.family: "DejaVu Sans"
									font.pointSize: 12
									color: "#666666"
									Layout.fillWidth: true
									wrapMode: Text.WordWrap
								}
							}
						}

						Rectangle {
							width: parent.width
							height: 80
							color: "#f8f9fa"
							border.color: "#dee2e6"
							border.width: 1
							radius: 4

							ColumnLayout {
								anchors.fill: parent
								anchors.margins: 15
								spacing: 8

								Text {
									text: "Liberation Sans"
									font.family: "Liberation Sans"
									font.pointSize: 16
									font.bold: true
									color: "#333333"
									Layout.fillWidth: true
								}

								Text {
									text: qsTr("Sample: Ahoj světe! The quick brown fox jumps over the lazy dog.")
									font.family: "Liberation Sans"
									font.pointSize: 12
									color: "#666666"
									Layout.fillWidth: true
									wrapMode: Text.WordWrap
								}
							}
						}

						Rectangle {
							width: parent.width
							height: 80
							color: "#f8f9fa"
							border.color: "#dee2e6"
							border.width: 1
							radius: 4

							ColumnLayout {
								anchors.fill: parent
								anchors.margins: 15
								spacing: 8

								Text {
									text: "Noto Sans"
									font.family: "Noto Sans"
									font.pointSize: 16
									font.bold: true
									color: "#333333"
									Layout.fillWidth: true
								}

								Text {
									text: qsTr("Sample: Ahoj světe! The quick brown fox jumps over the lazy dog.")
									font.family: "Noto Sans"
									font.pointSize: 12
									color: "#666666"
									Layout.fillWidth: true
									wrapMode: Text.WordWrap
								}
							}
						}

						Rectangle {
							width: parent.width
							height: 80
							color: "#f8f9fa"
							border.color: "#dee2e6"
							border.width: 1
							radius: 4

							ColumnLayout {
								anchors.fill: parent
								anchors.margins: 15
								spacing: 8

								Text {
									text: "FreeSans (GNU FreeFont)"
									font.family: "FreeSans"
									font.pointSize: 16
									font.bold: true
									color: "#333333"
									Layout.fillWidth: true
								}

								Text {
									text: qsTr("Sample: Ahoj světe! The quick brown fox jumps over the lazy dog.")
									font.family: "FreeSans"
									font.pointSize: 12
									color: "#666666"
									Layout.fillWidth: true
									wrapMode: Text.WordWrap
								}
							}
						}

						Rectangle {
							width: parent.width
							height: 80
							color: "#f8f9fa"
							border.color: "#dee2e6"
							border.width: 1
							radius: 4

							ColumnLayout {
								anchors.fill: parent
								anchors.margins: 15
								spacing: 8

								Text {
									text: "Droid Sans"
									font.family: "Droid Sans"
									font.pointSize: 16
									font.bold: true
									color: "#333333"
									Layout.fillWidth: true
								}

								Text {
									text: qsTr("Sample: Ahoj světe! The quick brown fox jumps over the lazy dog.")
									font.family: "Droid Sans"
									font.pointSize: 12
									color: "#666666"
									Layout.fillWidth: true
									wrapMode: Text.WordWrap
								}
							}
						}

						Rectangle {
							width: parent.width
							height: 80
							color: "#f8f9fa"
							border.color: "#dee2e6"
							border.width: 1
							radius: 4

							ColumnLayout {
								anchors.fill: parent
								anchors.margins: 15
								spacing: 8

								Text {
									text: "Source Sans Pro"
									font.family: "Source Sans Pro"
									font.pointSize: 16
									font.bold: true
									color: "#333333"
									Layout.fillWidth: true
								}

								Text {
									text: qsTr("Sample: Ahoj světe! The quick brown fox jumps over the lazy dog.")
									font.family: "Source Sans Pro"
									font.pointSize: 12
									color: "#666666"
									Layout.fillWidth: true
									wrapMode: Text.WordWrap
								}
							}
						}
					}
				}
			}
		}
	}
}
