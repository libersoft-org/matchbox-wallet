import QtQuick 6.8
import "../components"

BaseMenu {
	id: root
	property string title: tr("power.title")
	property bool showPowerButton: false

	MenuButton {
		text: tr("power.quit")
		onClicked: Qt.quit()
	}

	MenuButton {
		text: tr("power.reboot")
		onClicked: {
			console.log("Reboot requested");
			if (typeof NodeJS !== 'undefined') {
				NodeJS.msg("powerReboot", {}, function (result) {
					console.log("Reboot result:", JSON.stringify(result));
					if (result.status === 'success') {
						console.log("System reboot initiated successfully");
					} else {
						console.error("Failed to reboot system:", result.message);
					}
				});
			}
		}
	}

	MenuButton {
		text: tr("power.shutdown")
		onClicked: {
			console.log("Shutdown requested");
			if (typeof NodeJS !== 'undefined') {
				NodeJS.msg("powerShutdown", {}, function (result) {
					console.log("Shutdown result:", JSON.stringify(result));
					if (result.status === 'success') {
						console.log("System shutdown initiated successfully");
					} else {
						console.error("Failed to shutdown system:", result.message);
					}
				});
			}
		}
	}
}
