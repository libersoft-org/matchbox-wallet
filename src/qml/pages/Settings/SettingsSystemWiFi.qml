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
	signal wifiDisconnected
	property var networks: []
	property bool isScanning: false
	property var currentConnection: null
	property bool isConnected: currentConnection && currentConnection.connected
	property string connectedSSID: (currentConnection && currentConnection.connected) ? (currentConnection.ssid || "") : ""
	property int connectionStrength: (currentConnection && currentConnection.connected) ? (currentConnection.strength || 0) : 0

	// Debug properties - add watchers
	onIsConnectedChanged: console.log("DEBUG: isConnected changed to:", isConnected)
	onConnectedSSIDChanged: console.log("DEBUG: connectedSSID changed to:", connectedSSID)
	onCurrentConnectionChanged: console.log("DEBUG: currentConnection changed to:", JSON.stringify(currentConnection))

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
		console.log("Updating current connection status...");
		NodeUtils.msg("wifiGetConnectionStatus", {}, function (response) {
			console.log("WiFi connection status response:", JSON.stringify(response));
			if (response.status === 'success') {
				var oldConnection = currentConnection;
				currentConnection = response.data;
				console.log("Updated currentConnection:", JSON.stringify(currentConnection));
				// Emit property change - force update derived properties
				if (!oldConnection || oldConnection.connected !== currentConnection.connected || oldConnection.ssid !== currentConnection.ssid || oldConnection.strength !== currentConnection.strength) {
					console.log("Connection state changed - forcing UI update");
					// Trigger property change notifications
					isConnectedChanged();
					connectedSSIDChanged();
					connectionStrengthChanged();
				}
			} else {
				console.log("Failed to get connection status:", response.message);
			}
		});
	}

	function connectToNetwork(ssid, password) {
		console.log("Connecting to network:", ssid);
		NodeUtils.msg("wifiConnectToNetwork", {
			ssid: ssid,
			password: password
		}, function (response) {
			console.log("wifiConnectToNetwork response:", JSON.stringify(response));
			if (response.status === 'success') {
				console.log("WiFi connected successfully to", ssid);
				// Immediately update connection status
				updateCurrentConnection();
			} else {
				console.log("Failed to connect to WiFi:", response.message);
			}
		});
	}

	function disconnectFromWifi() {
		console.log("disconnectFromWifi() called");
		NodeUtils.msg("wifiDisconnect", {}, function (response) {
			console.log("wifiDisconnect response:", JSON.stringify(response));
			if (response.status === 'success') {
				console.log("WiFi disconnected successfully");
				// Immediately update connection status
				updateCurrentConnection();
				// Emit signal for main window
				root.wifiDisconnected();
			} else {
				console.log("Failed to disconnect WiFi:", response.message);
			}
		});
	}

	// Scan on component load
	Component.onCompleted: {
		console.log("SettingsSystemWiFi component loaded");
		updateCurrentConnection(); // Immediate update of connection status
		scanNetworks();
	}

	// Update when visibility changes
	onVisibleChanged: {
		if (visible) {
			console.log("WiFi settings page became visible - updating connection status");
			updateCurrentConnection();
		}
	}

	Column {
		anchors.fill: parent
		spacing: window.height * 0.02

		// Connection status text
		Text {
			id: statusText
			text: {
				if (root.isConnected)
					return tr("menu.settings.system.wifi.connected") + ':';
				return tr("menu.settings.system.wifi.disconnected");
			}
			font.pixelSize: window.height * 0.05
			color: root.isConnected ? colors.success : colors.error
			anchors.horizontalCenter: parent.horizontalCenter
			horizontalAlignment: Text.AlignHCenter
			wrapMode: Text.WordWrap
		}

		Text {
			id: connectedNetworkText
			text: root.connectedSSID
			font.pixelSize: window.height * 0.05
			font.bold: true
			anchors.horizontalCenter: parent.horizontalCenter
			horizontalAlignment: Text.AlignHCenter
			wrapMode: Text.WordWrap
			color: colors.primaryForeground
			visible: root.isConnected && root.connectedSSID !== ""
		}

		// Signal strength for connected network
		SignalStrength {
			anchors.horizontalCenter: parent.horizontalCenter
			strength: root.connectionStrength
			visible: root.isConnected
		}

		// Change button
		MenuButton {
			id: changeMenuButton
			text: tr("menu.settings.system.wifi.change")
			onClicked: root.wifiListRequested()
		}

		// Disconnect button
		MenuButton {
			id: disconnectMenuButton
			text: tr("menu.settings.system.wifi.disconnect")
			visible: root.isConnected
			onClicked: {
				console.log("Disconnect button clicked");
				root.disconnectFromWifi();
			}
		}
	}

	// Listen for global WiFi state changes from main window
	Connections {
		target: window
		function onWifiConnectionChanged() {
			console.log("WiFi connection changed - updating status");
			updateCurrentConnection();
		}
		function onWifiStatusUpdated() {
			console.log("WiFi status updated - refreshing connection info");
			updateCurrentConnection();
		}
	}
}
