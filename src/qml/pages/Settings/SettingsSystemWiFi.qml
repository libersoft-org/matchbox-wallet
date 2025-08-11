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

	ColumnLayout {
		Layout.fillWidth: true
		Layout.fillHeight: true
		spacing: 15

		Text {
			text: tr("settings.system.wifi.current.status")
			font.pixelSize: 16
			font.bold: true
			color: colors.primaryForeground
			Layout.alignment: Qt.AlignHCenter
		}

		// Connection status text
		Text {
			id: statusText
			text: {
				if (currentConnection && currentConnection.connected)
					return tr("settings.system.wifi.connected.to") + ':';
				return tr("settings.system.wifi.not.connected");
			}
			font.pointSize: 12
			color: {
				if (currentConnection && currentConnection.connected)
					return colors.success;
				return colors.error;
			}
			Layout.alignment: Qt.AlignHCenter
			horizontalAlignment: Text.AlignHCenter
			wrapMode: Text.WordWrap
			Layout.fillWidth: true
		}

		Text {
			id: connectedNetworkText
			text: {
				if (currentConnection && currentConnection.connected)
					return currentConnection.ssid || "";
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
				if (currentConnection && currentConnection.connected)
					return currentConnection.strength || 0;
				return 0;
			}
			visible: currentConnection && currentConnection.connected
		}

		// Search button
		MenuButton {
			id: searchMenuButton
			Layout.fillWidth: true
			text: tr("settings.system.wifi.search")
			onClicked: root.wifiListRequested()
		}
	}
}
