import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../utils/NodeUtils.js" as NodeUtils

Rectangle {
	id: root
	color: colors.primaryBackground
	property string title: tr("menu.settings.system.wifi.title")
	signal backRequested
	signal powerOffRequested
	signal wifiListRequested

	// Local alias for easier access to colors
	property var colors: window.colors

	// WiFi state
	property var networks: []
	property bool isScanning: false
	property var currentConnection: null

	// Functions for WiFi management
	function scanNetworks() {
		isScanning = true;
		NodeUtils.msg("wifiScanNetworks", {}, function (response) {
			isScanning = false;
			if (response.status === 'success') {
				networks = response.data.networks || [];
				updateCurrentConnection();
			} else {
				console.log("WiFi scan failed:", response.message);
			}
		});
	}

	function updateCurrentConnection() {
		NodeUtils.msg("wifiGetConnectionStatus", {}, function (response) {
			if (response.status === 'success') {
				currentConnection = response.data;
			}
		});
	}

	// Scan on component load
	Component.onCompleted: {
		scanNetworks();
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 30
		spacing: 30

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
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
					if (currentConnection && currentConnection.connected) {
						return tr("settings.system.wifi.connected.to") + ':';
					}
					return tr("settings.system.wifi.not.connected");
				}
				font.pointSize: 12
				color: {
					if (currentConnection && currentConnection.connected) {
						return root.colors.success;
					}
					return root.colors.disabledForeground;
				}
				Layout.alignment: Qt.AlignHCenter
				horizontalAlignment: Text.AlignHCenter
				wrapMode: Text.WordWrap
				Layout.fillWidth: true
			}

			Text {
				id: connectedNetworkText
				text: {
					if (currentConnection && currentConnection.connected) {
						return currentConnection.ssid || "";
					}
					return "";
				}
				font.pointSize: 20
				font.bold: true
				Layout.alignment: Qt.AlignHCenter
				horizontalAlignment: Text.AlignHCenter
				wrapMode: Text.WordWrap
				Layout.fillWidth: true
				color: colors.primaryForeground
			}

			// Signal strength for connected network
			SignalStrength {
				Layout.alignment: Qt.AlignHCenter
				Layout.preferredWidth: 50
				Layout.preferredHeight: 16
				strength: {
					if (currentConnection && currentConnection.connected) {
						return currentConnection.strength || 0;
					}
					return 0;
				}
				activeColor: root.colors.success
				inactiveColor: root.colors.disabledForeground
				visible: currentConnection && currentConnection.connected
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
