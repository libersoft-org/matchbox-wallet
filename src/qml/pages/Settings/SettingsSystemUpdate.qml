import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../utils/NodeUtils.js" as Node

ScrollableContainer {
	id: root
	property string title: tr("menu.settings.system.update.title")
	property string appVersion: applicationVersion
	property string latestAppVersion: tr("common.loading")
	property string systemVersion: tr("common.loading")
	property string latestSystemVersion: tr("common.loading")

	Component.onCompleted: {
		loadVersions();
	}

	function loadVersions() {
		// Application version is already available from C++ as applicationVersion
		// No need to call Node.js for current app version

		// Load latest application version
		Node.msg("systemGetLatestAppVersion", {}, function (response) {
			if (response.status === 'success') {
				root.latestAppVersion = response.data.version;
			} else {
				root.latestAppVersion = tr("common.error");
			}
		});

		// Load current system version
		Node.msg("systemGetCurrentVersion", {}, function (response) {
			if (response.status === 'success') {
				root.systemVersion = response.data.fullVersion || response.data.version;
			} else {
				root.systemVersion = tr("common.error");
			}
		});

		// Load latest system version
		Node.msg("systemGetLatestVersion", {}, function (response) {
			if (response.status === 'success') {
				root.latestSystemVersion = response.data.fullVersion || response.data.version;
			} else {
				root.latestSystemVersion = tr("common.error");
			}
		});
	}

	Column {
		width: parent.width
		spacing: 20

		// Application versions
		Column {
			anchors.horizontalCenter: parent.horizontalCenter
			spacing: 10

			Text {
				text: tr("menu.settings.system.update.app.current") + ":"
				color: colors.primaryForeground
				font.pixelSize: window.height * 0.03
				anchors.horizontalCenter: parent.horizontalCenter
			}

			Text {
				text: root.appVersion
				font.pixelSize: window.height * 0.05
				color: root.appVersion === root.latestAppVersion ? colors.success : colors.error
				anchors.horizontalCenter: parent.horizontalCenter
			}

			Text {
				text: tr("menu.settings.system.update.app.latest") + ":"
				color: colors.primaryForeground
				font.pixelSize: window.height * 0.03
				anchors.horizontalCenter: parent.horizontalCenter
			}

			Text {
				text: root.latestAppVersion
				font.pixelSize: window.height * 0.05
				color: colors.success
				anchors.horizontalCenter: parent.horizontalCenter
			}
		}

		// System versions
		Column {
			anchors.horizontalCenter: parent.horizontalCenter
			spacing: 10

			Text {
				text: tr("menu.settings.system.update.system.current") + ":"
				color: colors.primaryForeground
				font.pixelSize: window.height * 0.03
				anchors.horizontalCenter: parent.horizontalCenter
			}

			Text {
				text: root.systemVersion
				font.pixelSize: window.height * 0.05
				color: root.systemVersion === root.latestSystemVersion ? colors.success : colors.error
				anchors.horizontalCenter: parent.horizontalCenter
			}

			Text {
				text: tr("menu.settings.system.update.system.latest") + ":"
				color: colors.primaryForeground
				font.pixelSize: window.height * 0.03
				anchors.horizontalCenter: parent.horizontalCenter
			}

			Text {
				text: root.latestSystemVersion
				font.pixelSize: window.height * 0.05
				color: colors.success
				anchors.horizontalCenter: parent.horizontalCenter
			}
		}

		// Update buttons
		Column {
			anchors.horizontalCenter: parent.horizontalCenter
			spacing: 15
			width: parent.width * 0.8

			MenuButton {
				text: tr("menu.settings.system.update.app.button")
				anchors.horizontalCenter: parent.horizontalCenter
				onClicked: {
					console.log("Update application clicked");
					// TODO: Implement application update logic
				}
			}

			MenuButton {
				text: tr("menu.settings.system.update.system.button")
				anchors.horizontalCenter: parent.horizontalCenter
				onClicked: {
					console.log("Update system clicked");
					// TODO: Implement system update logic
				}
			}
		}
	}
}
