import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../static"
import "../../utils/NodeUtils.js" as NodeUtils

Rectangle {
	id: root

	Colors {
		id: colors
	}

	TranslationManager {
		id: translationManager
	}

	color: colors.primaryBackground
	property string title: tr("menu.settings.system.firewall.exceptions.title")

	signal portAdded(var portData)
	signal addCancelled

	property bool isLoading: false
	property string portNumber: ""
	property string portDescription: ""
	property string portProtocol: "tcp"

	function addException() {
		if (!portInput.text || portInput.text.trim() === "") {
			console.log('Port number is required');
			return;
		}

		var port = parseInt(portInput.text.trim());
		if (isNaN(port) || port < 1 || port > 65535) {
			console.log('Invalid port number');
			return;
		}

		root.isLoading = true;
		var description = descriptionInput.text.trim() || ("Port " + port);

		if (root.portProtocol === "both") {
			// Add both TCP and UDP
			var addCount = 0;
			var totalAdds = 2;
			var hasError = false;

			function onAddComplete() {
				addCount++;
				if (addCount === totalAdds && !hasError) {
					root.isLoading = false;
					console.log('Both TCP and UDP ports added successfully');
					root.portAdded({
						port: port,
						protocol: "both",
						description: description
					});
				}
			}

			// Add TCP
			NodeUtils.msg('firewallAddException', {
				port: port,
				protocol: "tcp",
				description: description + " (TCP)"
			}, function (response) {
				if (response.status === 'success') {
					onAddComplete();
				} else {
					hasError = true;
					root.isLoading = false;
					console.log('Failed to add TCP port:', response.message);
				}
			});

			// Add UDP
			NodeUtils.msg('firewallAddException', {
				port: port,
				protocol: "udp",
				description: description + " (UDP)"
			}, function (response) {
				if (response.status === 'success') {
					onAddComplete();
				} else {
					hasError = true;
					root.isLoading = false;
					console.log('Failed to add UDP port:', response.message);
				}
			});
		} else {
			// Add single protocol
			NodeUtils.msg('firewallAddException', {
				port: port,
				protocol: root.portProtocol,
				description: description
			}, function (response) {
				root.isLoading = false;
				if (response.status === 'success') {
					console.log('Port added successfully');
					root.portAdded({
						port: port,
						protocol: root.portProtocol,
						description: description
					});
				} else {
					console.log('Failed to add port:', response.message);
				}
			});
		}
	}

	ScrollableContainer {
		anchors.fill: parent

		Column {
			width: parent.width
			spacing: 20

			// Form
			Column {
				width: parent.width
				spacing: 20

				// Port number
				Column {
					width: parent.width
					spacing: 10

					Text {
						text: tr("menu.settings.system.firewall.exceptions.port")
						font.pixelSize: 16
						color: colors.primaryForeground
					}

					Input {
						id: portInput
						inputWidth: parent.width
						inputHeight: 50
						inputPlaceholder: tr("menu.settings.system.firewall.exceptions.portPlaceholder")
						inputType: "number"
						inputAutoFocus: true
					}
				}

				// Protocol selection
				Column {
					width: parent.width
					spacing: 10

					Text {
						text: tr("menu.settings.system.firewall.exceptions.protocol")
						font.pixelSize: 16
						color: colors.primaryForeground
					}

					Row {
						width: parent.width
						spacing: 10

						Radio {
							id: tcpRadio
							text: "TCP"
							checked: root.portProtocol === "tcp"
							onCheckedChanged: {
								if (checked)
									root.portProtocol = "tcp";
							}
						}

						Radio {
							id: udpRadio
							text: "UDP"
							checked: root.portProtocol === "udp"
							onCheckedChanged: {
								if (checked)
									root.portProtocol = "udp";
							}
						}

						Radio {
							id: bothRadio
							text: "TCP + UDP"
							checked: root.portProtocol === "both"
							onCheckedChanged: {
								if (checked)
									root.portProtocol = "both";
							}
						}
					}
				}

				// Description
				Column {
					width: parent.width
					spacing: 10

					Text {
						text: tr("menu.settings.system.firewall.exceptions.description")
						font.pixelSize: 16
						color: colors.primaryForeground
					}

					Input {
						id: descriptionInput
						inputWidth: parent.width
						inputHeight: 50
						inputPlaceholder: tr("menu.settings.system.firewall.exceptions.descriptionPlaceholder")
					}
				}
			}

			// Buttons
			Column {
				width: parent.width
				spacing: 15

				MenuButton {
					text: tr("menu.settings.system.firewall.exceptions.add")
					enabled: !root.isLoading && portInput.text.trim() !== ""
					width: parent.width
					backgroundColor: colors.success
					onClicked: root.addException()
				}
			}
		}
	}
}
