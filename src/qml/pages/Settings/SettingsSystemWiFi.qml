import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../utils/NodeUtils.js" as NodeUtils

Rectangle {
	id: root
	color: colors.primaryBackground
	property string title: tr("menu.settings.system.wifi.title")
	signal wifiListRequested

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

	Column {
		anchors.fill: parent
		spacing: window.height * 0.02

		// Connection status text
		Text {
			id: statusText
			text: {
				if (currentConnection && currentConnection.connected)
					return tr("menu.settings.system.wifi.connected") + ':';
				return tr("menu.settings.system.wifi.disconnected");
			}
			font.pixelSize: window.height * 0.05
			color: currentConnection && currentConnection.connected ? colors.success : colors.error
			anchors.horizontalCenter: parent.horizontalCenter
			horizontalAlignment: Text.AlignHCenter
			wrapMode: Text.WordWrap
		}

		Text {
			id: connectedNetworkText
			text: {
				if (currentConnection && currentConnection.connected)
					return currentConnection.ssid || "";
				return "";
			}
			font.pixelSize: window.height * 0.05
			font.bold: true
			anchors.horizontalCenter: parent.horizontalCenter
			horizontalAlignment: Text.AlignHCenter
			wrapMode: Text.WordWrap
			color: colors.primaryForeground
		}

		// Signal strength for connected network
		SignalStrength {
			anchors.horizontalCenter: parent.horizontalCenter
			strength: currentConnection && currentConnection.connected ? currentConnection.strength || 0 : 0
			visible: currentConnection && currentConnection.connected
		}

		// Search button
		MenuButton {
			id: searchMenuButton
			text: tr("settings.system.wifi.search")
			onClicked: root.wifiListRequested()
		}
	}
}
