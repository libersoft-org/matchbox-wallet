import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

BaseMenu {
	id: root
	title: tr("menu.power.title")
	property bool showPowerButton: false

	MenuButton {
		text: tr("menu.power.quit")
		onClicked: Qt.quit()
	}

	MenuButton {
		text: tr("menu.power.reboot")
		onClicked: {
			console.log("Reboot requested");
			if (typeof NodeJS !== 'undefined') {
				NodeJS.msg("systemReboot", {}, function(result) {
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
		text: tr("menu.power.shutdown")
		onClicked: {
			console.log("Shutdown requested");
			if (typeof NodeJS !== 'undefined') {
				NodeJS.msg("systemShutdown", {}, function(result) {
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
