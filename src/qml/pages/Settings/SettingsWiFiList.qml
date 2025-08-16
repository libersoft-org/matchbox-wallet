import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../utils/NodeUtils.js" as NodeUtils

Rectangle {
	id: root
	color: colors.primaryBackground
	property string title: tr("menu.settings.wifi.list.title")

	// WiFi state
	property var networks: []
	property bool isScanning: false

	// Timer for timeout protection
	Timer {
		id: scanTimeoutTimer
		interval: 10000
		onTriggered: {
			console.log("QML: WiFi scan timeout");
			isScanning = false;
		}
	}

	// Functions for WiFi management
	function scanNetworks() {
		console.log("QML: Starting WiFi scan...");
		isScanning = true;

		// Clear existing networks immediately
		networks = [];
		console.log("QML: Networks cleared for refresh");

		scanTimeoutTimer.start();

		console.log("QML: About to call NodeUtils.msg for wifiScanNetworks");
		NodeUtils.msg("wifiScanNetworks", {}, function (response) {
			console.log("QML: WiFi scan callback executed!");
			console.log("QML: WiFi scan response received:", JSON.stringify(response));
			scanTimeoutTimer.stop();
			isScanning = false;
			if (response.status === 'success') {
				console.log("QML: Networks data:", JSON.stringify(response.data.networks));

				// Safe assignment with validation
				var newNetworks = response.data.networks || [];
				if (Array.isArray(newNetworks) && newNetworks.length > 0) {
					console.log("QML: Setting", newNetworks.length, "networks directly");
					networks = newNetworks;
					console.log("QML: Networks property set to:", JSON.stringify(networks));
				} else {
					console.log("QML: No networks found or invalid data format");
					networks = [];
				}
			} else {
				console.log("WiFi scan failed:", response.message);
				networks = []; // Clear networks on failure
			}
		});
		console.log("QML: NodeUtils.msg call completed");
	}

	function connectToNetwork(ssid, password) {
		NodeUtils.msg("wifiConnectToNetwork", {
			ssid: ssid,
			password: password || ""
		}, function (response) {
			if (response.status === 'success') {
				console.log("Successfully connected to", ssid);
				// Emit global signals for WiFi status update
				if (typeof window !== 'undefined') {
					window.wifiConnectionChanged();
					window.wifiStatusUpdated();
				}
				// Go back to main WiFi page after successful connection
				window.goBack();
			} else {
				console.log("Failed to connect to", ssid, "Error:", response.message);
			}
		});
	}

	// Scan on component load
	Component.onCompleted: {
		scanNetworks();
	}

	ScrollView {
		anchors.fill: parent
		contentHeight: contentColumn.height

		Column {
			id: contentColumn
			width: parent.width
			spacing: root.height * 0.03

			// Refresh button
			MenuButton {
				width: parent.width
				text: root.isScanning ? tr("menu.settings.wifi.list.scanning") : tr("menu.settings.wifi.list.refresh")
				enabled: !root.isScanning
				onClicked: {
					root.scanNetworks();
				}
			}

			// Networks container - using Repeater instead of ListView for simplicity
			Rectangle {
				width: parent.width
				height: childrenRect.height
				color: "transparent"

				Column {
					width: parent.width
					spacing: 2

					Repeater {
						model: root.networks
						delegate: MenuButton {
							width: parent.width
							height: 50
							text: {
								if (!modelData)
									return "Loading...";
								var name = modelData.name || "Unknown";
								var secured = modelData.secured ? " 🔒" : " 🔓";
								return name + secured;
							}

							onClicked: {
								if (modelData && modelData.name) {
									console.log("QML: Clicked network:", modelData.name);
									var isSecured = modelData.secured || false;
									if (isSecured) {
										// Open password page for secured networks
										window.goPage('Settings/SettingsWiFiListPassword.qml', null, {
											"networkName": modelData.name,
											"isSecured": isSecured
										});
									} else {
										// Connect directly to open networks
										connectToNetwork(modelData.name, "");
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
