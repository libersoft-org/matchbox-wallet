import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

Rectangle {
	id: root
	color: AppConstants.primaryBackground
	property string title: tr("settings.system.wifi.title")
	signal backRequested
	signal powerOffRequested
	signal wifiListRequested

	// WiFi Manager instance
	WiFiManager {
		id: wifiManager

		onConnectionResult: function (ssid, success, error) {
			if (success) {
				console.log("Successfully connected to", ssid);
			} else {
				console.log("Failed to connect to", ssid, "Error:", error);
			}
		}
	}

	// Scan on component load to get current connection status
	Component.onCompleted: {
		wifiManager.scanNetworks();
	}

	// Main WiFi status container
	Rectangle {
		anchors.fill: parent
		anchors.margins: root.width * 0.05
		anchors.topMargin: root.height * 0.03
		color: "white"
		border.color: "#cccccc"
		border.width: 1
		radius: 8

		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 30
			spacing: 30

			// Current connection status
			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: root.height * 0.4
				color: "#f8f9fa"
				border.color: "#dee2e6"
				border.width: 1
				radius: 10

				ColumnLayout {
					anchors.fill: parent
					anchors.margins: 20
					spacing: 15

					Text {
						text: tr("settings.system.wifi.current.status")
						font.pointSize: 14
						font.bold: true
						color: "#333333"
						Layout.alignment: Qt.AlignHCenter
					}

					// WiFi icon
					Text {
						text: "📶"
						font.pointSize: 32
						Layout.alignment: Qt.AlignHCenter
					}

					// Connection status text
					Text {
						id: statusText
						text: {
							for (let i = 0; i < wifiManager.networks.length; i++) {
								if (wifiManager.networks[i].connected) {
									return tr("settings.system.wifi.connected.to", wifiManager.networks[i].name);
								}
							}
							return tr("settings.system.wifi.not.connected");
						}
						font.pointSize: 12
						color: {
							for (let i = 0; i < wifiManager.networks.length; i++) {
								if (wifiManager.networks[i].connected) {
									return "#28a745";
								}
							}
							return "#6c757d";
						}
						Layout.alignment: Qt.AlignHCenter
						horizontalAlignment: Text.AlignHCenter
						wrapMode: Text.WordWrap
						Layout.fillWidth: true
					}

					// Signal strength for connected network
					Row {
						spacing: 3
						Layout.alignment: Qt.AlignHCenter
						visible: {
							for (let i = 0; i < wifiManager.networks.length; i++) {
								if (wifiManager.networks[i].connected) {
									return true;
								}
							}
							return false;
						}

						Repeater {
							model: 4
							Rectangle {
								width: 8
								height: (index + 1) * 4
								color: {
									for (let i = 0; i < wifiManager.networks.length; i++) {
										if (wifiManager.networks[i].connected) {
											return index < wifiManager.networks[i].strength ? "#28a745" : "#dee2e6";
										}
									}
									return "#dee2e6";
								}
								radius: 2
							}
						}
					}
				}
			}

			// Search button
			Button {
				id: searchButton
				Layout.fillWidth: true
				Layout.preferredHeight: root.height * 0.15
				text: tr("settings.system.wifi.search")

				background: Rectangle {
					color: searchButton.pressed ? "#0066cc" : (searchButton.hovered ? "#3399ff" : "#007bff")
					radius: 10
					border.color: "#0056b3"
					border.width: 1
				}

				contentItem: Text {
					text: searchButton.text
					font.pointSize: 14
					font.bold: true
					color: "white"
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
				}

				onClicked: {
					root.wifiListRequested();
				}
			}
		}
	}
}
