import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../utils/NodeUtils.js" as NodeUtils

Rectangle {
	id: root
	color: colors.primaryBackground
	property string title: tr("settings.system.wifi.list.title")
	signal backRequested
	signal powerOffRequested

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
				// Go back to main WiFi page after successful connection
				root.backRequested();
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

			// Title
			Text {
				text: root.title
				font.pixelSize: root.height * 0.06
				font.bold: true
				color: colors.primaryForeground
				horizontalAlignment: Text.AlignHCenter
				width: parent.width
				topPadding: root.height * 0.05
				bottomPadding: root.height * 0.03
			}

			// Refresh button
			MenuButton {
				width: parent.width
				text: root.isScanning ? tr("settings.system.wifi.scanning") : tr("settings.system.wifi.refresh")
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
									connectDialog.networkName = modelData.name;
									connectDialog.isSecured = modelData.secured || false;
									connectDialog.open();
								}
							}
						}
					}
				}
			}
		}
	}

	// WiFi connection dialog
	Dialog {
		id: connectDialog
		title: tr("settings.system.wifi.connect.title")
		modal: true
		anchors.centerIn: parent
		width: 350
		height: isSecured ? 200 : 150

		property string networkName: ""
		property bool isSecured: false

		contentItem: Rectangle {
			color: "white"

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: 20
				spacing: 15

				Text {
					text: tr("settings.system.wifi.connect.network").arg(connectDialog.networkName)
					wrapMode: Text.WordWrap
					Layout.fillWidth: true
					font.bold: true
				}

				// Password field (only for secured networks)
				ColumnLayout {
					Layout.fillWidth: true
					visible: connectDialog.isSecured
					spacing: 5

					Text {
						text: tr("settings.system.wifi.connect.password")
						font.pointSize: 10
					}

					TextField {
						id: passwordField
						Layout.fillWidth: true
						echoMode: TextInput.Password
						placeholderText: tr("settings.system.wifi.connect.password.placeholder")
					}
				}

				Text {
					text: connectDialog.isSecured ? "" : tr("settings.system.wifi.connect.open")
					visible: !connectDialog.isSecured
					font.pointSize: 10
					color: colors.disabledForeground
				}

				RowLayout {
					Layout.alignment: Qt.AlignHCenter
					spacing: 10

					Button {
						text: tr("common.cancel")
						onClicked: {
							passwordField.text = "";
							connectDialog.close();
						}

						background: Rectangle {
							color: parent.pressed ? "#e0e0e0" : (parent.hovered ? "#f0f0f0" : "#f8f9fa")
							radius: 4
							border.color: "#6c757d"
							border.width: 1
						}
					}

					Button {
						text: tr("settings.system.wifi.connect.button")
						onClicked: {
							root.connectToNetwork(connectDialog.networkName, passwordField.text);
							passwordField.text = "";
							connectDialog.close();
						}

						background: Rectangle {
							color: parent.pressed ? "#0066cc" : (parent.hovered ? "#3399ff" : "#007bff")
							radius: 4
							border.color: "#0056b3"
							border.width: 1
						}

						contentItem: Text {
							text: parent.text
							color: "white"
							horizontalAlignment: Text.AlignHCenter
							verticalAlignment: Text.AlignVCenter
						}
					}
				}
			}
		}
	}
}
