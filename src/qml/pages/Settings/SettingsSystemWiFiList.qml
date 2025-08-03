import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

Rectangle {
	id: root
	color: Colors.primaryBackground
	property string title: tr("settings.system.wifi.list.title")
	signal backRequested
	signal powerOffRequested

	// WiFi Manager instance
	WiFiManager {
		id: wifiManager

		onConnectionResult: function (ssid, success, error) {
			if (success) {
				console.log("Successfully connected to", ssid);
				// Go back to main WiFi page after successful connection
				root.backRequested();
			} else {
				console.log("Failed to connect to", ssid, "Error:", error);
			}
		}
	}

	// Scan on component load
	Component.onCompleted: {
		wifiManager.scanNetworks();
	}

	BaseMenu {
		anchors.fill: parent
		title: root.title

		// Refresh button
		MenuButton {
			text: wifiManager.isScanning ? tr("settings.system.wifi.scanning") : tr("settings.system.wifi.refresh")
			enabled: !wifiManager.isScanning
			onClicked: {
				wifiManager.scanNetworks();
			}
		}

		// WiFi networks - dynamically create MenuButtons
		Repeater {
			model: wifiManager.networks
			MenuButton {
				text: modelData.name + (modelData.connected ? " ✓" : "") + (modelData.secured ? " 🔒" : " 🔓")
				backgroundColor: modelData.connected ? Colors.success : Colors.primaryBackground
				onClicked: {
					if (!modelData.connected) {
						connectDialog.networkName = modelData.name;
						connectDialog.isSecured = modelData.secured;
						connectDialog.open();
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
					text: tr("settings.system.wifi.connect.network", connectDialog.networkName)
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
					color: Colors.disabledForeground
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
							wifiManager.connectToNetwork(connectDialog.networkName, passwordField.text);
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
