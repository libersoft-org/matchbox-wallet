import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../utils/NodeUtils.js" as NodeUtils

Rectangle {
	id: root
	color: colors.primaryBackground
	property string title: tr("menu.settings.system.wifi.list.password.title")
	signal backRequested
	signal passwordEntered(string password)

	// Network properties
	property string networkName: ""
	property bool isSecured: true

	function connectToNetwork() {
		if (!root.networkName) {
			console.log("No network name provided");
			return;
		}

		var password = isSecured ? passwordInput.text : "";
		console.log("Connecting to network:", root.networkName, "with password length:", password.length);

		NodeUtils.msg("wifiConnectToNetwork", {
			ssid: root.networkName,
			password: password
		}, function (response) {
			if (response.status === 'success') {
				console.log("Successfully connected to", root.networkName);
				// Emit global signals for WiFi status update
				if (typeof window !== 'undefined') {
					window.wifiConnectionChanged();
					window.wifiStatusUpdated();
				}
				// Go back to WiFi settings page
				root.backRequested();
			} else {
				console.log("Failed to connect to", root.networkName, "Error:", response.message);
				errorText.text = tr("menu.settings.system.wifi.list.password.error") + ": " + response.message;
				errorText.visible = true;
			}
		});
	}

	ScrollableContainer {
		anchors.fill: parent

		Column {
			id: contentColumn
			anchors.fill: parent
			spacing: window.height * 0.03
			anchors.margins: window.height * 0.02

			// Network name display
			Text {
				text: tr("menu.settings.system.wifi.list.password.network") + ": " + root.networkName
				font.pixelSize: window.height * 0.04
				font.bold: true
				color: colors.primaryForeground
				anchors.horizontalCenter: parent.horizontalCenter
				horizontalAlignment: Text.AlignHCenter
				wrapMode: Text.WordWrap
			}

			// Security info
			Text {
				text: root.isSecured ? tr("menu.settings.system.wifi.list.password.secured") : tr("menu.settings.system.wifi.list.password.open")
				font.pixelSize: window.height * 0.035
				color: colors.primaryForeground
				anchors.horizontalCenter: parent.horizontalCenter
				horizontalAlignment: Text.AlignHCenter
				wrapMode: Text.WordWrap
			}

			// Password input (only for secured networks)
			Column {
				anchors.horizontalCenter: parent.horizontalCenter
				spacing: window.height * 0.01
				visible: root.isSecured

				Text {
					text: tr("menu.settings.system.wifi.list.password.enter")
					font.pixelSize: window.height * 0.035
					color: colors.primaryForeground
					anchors.horizontalCenter: parent.horizontalCenter
				}

				Input {
					id: passwordInput
					inputWidth: window.width * 0.8
					inputHeight: window.height * 0.06
					inputFontSize: window.height * 0.035
					inputPlaceholder: tr("menu.settings.system.wifi.list.password.placeholder")
					inputEchoMode: TextInput.Password
					inputTextColor: colors.primaryForeground
					inputBackgroundColor: colors.primaryBackground
					inputBorderColor: colors.primaryForeground
					inputAutoFocus: root.isSecured

					onInputReturnPressed: {
						root.connectToNetwork();
					}
				}
			}

			// Error message
			Text {
				id: errorText
				text: ""
				font.pixelSize: window.height * 0.03
				color: colors.error
				anchors.horizontalCenter: parent.horizontalCenter
				horizontalAlignment: Text.AlignHCenter
				wrapMode: Text.WordWrap
				visible: false
			}

			// Connect button
			MenuButton {
				text: tr("menu.settings.system.wifi.list.password.connect")
				anchors.horizontalCenter: parent.horizontalCenter
				onClicked: root.connectToNetwork()
			}

			// Cancel button
			MenuButton {
				text: tr("common.cancel")
				anchors.horizontalCenter: parent.horizontalCenter
				onClicked: root.backRequested()
			}
		}
	}
}
