pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../static"
import "../../utils/NodeUtils.js" as NodeUtils

Rectangle {
	id: root
	color: colors.primaryBackground
	property string title: tr("menu.settings.system.firewall.title")
	property bool firewallEnabled: false
	property var allowedExceptions: []
	property bool isLoading: false
	signal addExceptionRequested

	Colors {
		id: colors
	}

	function onPortAdded() {
		loadFirewallStatus();
	}

	Component.onCompleted: {
		loadFirewallStatus();
	}

	function loadFirewallStatus() {
		root.isLoading = true;
		NodeUtils.msg('firewallGetStatus', {}, function (response) {
			root.isLoading = false;
			if (response.status === 'success') {
				root.firewallEnabled = response.data.enabled;
				root.allowedExceptions = response.data.rules || [];
				console.log('Firewall status loaded:', JSON.stringify(response.data));
			} else {
				console.log('Failed to load firewall status:', response.message);
			}
		});
	}

	function setFirewallEnabled(enabled) {
		root.isLoading = true;
		NodeUtils.msg('firewallSetEnabled', {
			enabled: enabled
		}, function (response) {
			root.isLoading = false;
			if (response.status === 'success') {
				root.firewallEnabled = enabled;
				console.log('Firewall', enabled ? 'enabled' : 'disabled');
			} else {
				console.log('Failed to change firewall status:', response.message);
			}
		});
	}

	function setExceptionEnabled(port, protocol, enabled, description) {
		root.isLoading = true;
		NodeUtils.msg('firewallSetExceptionEnabled', {
			port: port,
			protocol: protocol,
			enabled: enabled,
			description: description
		}, function (response) {
			root.isLoading = false;
			if (response.status === 'success') {
				console.log('Port', port + '/' + protocol, enabled ? 'enabled' : 'disabled');
				loadFirewallStatus(); // Reload to update UI
			} else {
				console.log('Failed to change port status:', response.message);
			}
		});
	}

	function removeException(port, protocol) {
		root.isLoading = true;
		NodeUtils.msg('firewallRemoveException', {
			port: port,
			protocol: protocol
		}, function (response) {
			root.isLoading = false;
			if (response.status === 'success') {
				root.loadFirewallStatus();
				console.log('Port removed successfully');
			} else {
				console.log('Failed to remove port:', response.message);
			}
		});
	}

	ScrollableContainer {
		anchors.fill: parent

		Column {
			width: parent.width
			spacing: 20

			// Header
			Column {
				width: parent.width
				spacing: 10

				Text {
					text: root.firewallEnabled ? tr("menu.settings.system.firewall.enabled") : tr("menu.settings.system.firewall.disabled")
					font.pixelSize: 16
					color: root.firewallEnabled ? colors.success : colors.warning
				}
			}

			// Enable/disable switch
			Row {
				width: parent.width
				spacing: 15

				Text {
					text: tr("menu.settings.system.firewall.enable")
					font.pixelSize: 18
					color: colors.primaryForeground
					anchors.verticalCenter: parent.verticalCenter
				}

				Switch {
					checked: root.firewallEnabled
					enabled: !root.isLoading
					onCheckedChanged: {
						if (checked !== root.firewallEnabled) {
							root.setFirewallEnabled(checked);
						}
					}
				}
			}

			// Add port button
			MenuButton {
				text: tr("menu.settings.system.firewall.exceptions.title")
				width: parent.width
				backgroundColor: colors.primaryForeground
				onClicked: root.addExceptionRequested()
			}

			// Ports list
			Column {
				width: parent.width
				spacing: 15

				Text {
					text: tr("menu.settings.system.firewall.ports.title")
					font.pixelSize: 20
					font.bold: true
					color: colors.primaryForeground
				}

				// Table header
				Row {
					width: parent.width
					spacing: 10

					Text {
						text: tr("menu.settings.system.firewall.ports.port")
						font.pixelSize: 14
						font.bold: true
						color: colors.primaryForeground
						width: 80
					}

					Text {
						text: tr("menu.settings.system.firewall.ports.description")
						font.pixelSize: 14
						font.bold: true
						color: colors.primaryForeground
						width: 200
					}

					Text {
						text: tr("menu.settings.system.firewall.ports.enabled")
						font.pixelSize: 14
						font.bold: true
						color: colors.primaryForeground
						width: 80
					}

					Text {
						text: ""
						width: 80
					}
				}

				// Ports list
				Repeater {
					model: root.allowedExceptions

					delegate: Row {
						required property var modelData

						width: parent.width
						spacing: 10

						Text {
							text: parent.modelData.port + "/" + parent.modelData.protocol
							font.pixelSize: 14
							color: colors.primaryForeground
							width: 80
							anchors.verticalCenter: parent.verticalCenter
						}

						Text {
							text: parent.modelData.description || ("Port " + parent.modelData.port)
							font.pixelSize: 14
							color: colors.primaryForeground
							width: 200
							anchors.verticalCenter: parent.verticalCenter
							elide: Text.ElideRight
						}

						Switch {
							checked: parent.modelData.action === "allow"
							enabled: !root.isLoading
							width: 80
							onCheckedChanged: {
								if (checked !== (parent.modelData.action === "allow")) {
									root.setExceptionEnabled(parent.modelData.port, parent.modelData.protocol, checked, parent.modelData.description);
								}
							}
						}

						MenuButton {
							text: tr("menu.settings.system.firewall.ports.remove")
							enabled: !root.isLoading && parent.modelData.action === "allow"
							width: 80
							backgroundColor: colors.error
							onClicked: root.removeException(parent.modelData.port, parent.modelData.protocol)
						}
					}
				}

				// No ports message
				Text {
					text: tr("menu.settings.system.firewall.ports.noPortsMessage")
					font.pixelSize: 16
					color: colors.primaryForeground
					visible: root.allowedExceptions.length === 0 && !root.isLoading
					anchors.horizontalCenter: parent.horizontalCenter
				}
			}
		}
	}
}
