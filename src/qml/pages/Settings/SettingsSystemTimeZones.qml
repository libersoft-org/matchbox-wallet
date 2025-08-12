import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../utils/NodeUtils.js" as NodeUtils

BaseMenu {
	id: root
	title: tr("menu.settings.system.time.timezone")
	signal timezoneSelected(string tz)
	property var timezones: []

	Component.onCompleted: {
		loadTimeZones()
	}

	function loadTimeZones() {
		console.log("Loading time zones...");
		NodeUtils.msg("systemListTimeZones", {}, function (response) {
			console.log("Time zones response:", JSON.stringify(response));
			if (response.status === 'success' && response.data) {
				timezones = response.data;
				console.log("Loaded", timezones.length, "time zones");
			} else {
				console.error("Failed to load time zones:", response.message || "Unknown error");
				timezones = ["UTC"];
			}
		});
	}

	Repeater {
		model: root.timezones
		delegate: MenuButton {
			text: modelData
			onClicked: root.timezoneSelected(modelData)
		}
	}
}
