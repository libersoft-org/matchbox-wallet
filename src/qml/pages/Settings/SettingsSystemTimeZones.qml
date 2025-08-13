pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../utils/NodeUtils.js" as NodeUtils

BaseMenu {
	id: root
	title: currentPath ? (tr("menu.settings.system.time.timezone") + " - " + currentPath.replace(/\//g, " / ")) : tr("menu.settings.system.time.timezone")
	signal timezoneSelected(string tz)
	signal pathSelected(string path)
	property var timezones: []
	property string currentPath: ""  // Current path (e.g., "" -> "America" -> "America/Argentina")
	property var displayItems: []

	Component.onCompleted: {
		if (currentPath) {
			// We're showing items for a specific path
			extractItemsForPath();
		} else {
			// We're showing top-level continents
			loadTimeZones();
		}
	}

	function loadTimeZones() {
		console.log("Loading time zones...");
		NodeUtils.msg("timeListTimeZones", {}, function (response) {
			console.log("Time zones response:", JSON.stringify(response));
			if (response.status === 'success' && response.data) {
				timezones = response.data;
				console.log("Loaded", timezones.length, "time zones");
				extractItemsForPath();
			} else {
				console.error("Failed to load time zones:", response.message || "Unknown error");
				timezones = ["UTC"];
				displayItems = [
					{
						text: "UTC",
						isTimezone: true,
						timezone: "UTC"
					}
				];
			}
		});
	}

	function extractItemsForPath() {
		var itemsSet = new Set();
		var pathDepth = currentPath ? currentPath.split("/").length : 0;

		// Add UTC at top level
		if (!currentPath) {
			itemsSet.add("UTC");
		}

		for (var i = 0; i < timezones.length; i++) {
			var timezone = timezones[i];

			// Skip UTC if we're not at root level
			if (timezone === "UTC" && currentPath)
				continue;

			if (currentPath) {
				// We're in a subdirectory - check if timezone starts with our path
				if (timezone.startsWith(currentPath + "/")) {
					var remainingPath = timezone.substring(currentPath.length + 1);
					var nextPart = remainingPath.split("/")[0];
					if (nextPart) {
						itemsSet.add(nextPart);
					}
				}
			} else {
				// We're at root level - extract top-level continents
				if (timezone.includes("/")) {
					var parts = timezone.split("/");
					itemsSet.add(parts[0]);
				}
			}
		}

		// Convert Set to Array and sort
		var itemsArray = Array.from(itemsSet).sort();
		var items = [];

		for (var j = 0; j < itemsArray.length; j++) {
			var item = itemsArray[j];
			var fullPath = currentPath ? (currentPath + "/" + item) : item;

			// Check if this is a complete timezone (leaf node)
			var isCompleteTimezone = false;
			for (var k = 0; k < timezones.length; k++) {
				if (timezones[k] === fullPath) {
					isCompleteTimezone = true;
					break;
				}
			}

			items.push({
				text: item.replace(/_/g, " "),
				isTimezone: isCompleteTimezone,
				timezone: isCompleteTimezone ? fullPath : null,
				path: isCompleteTimezone ? null : fullPath
			});
		}

		displayItems = items;
		console.log("Extracted", items.length, "items for path:", currentPath || "root");
	}

	Repeater {
		model: root.displayItems
		delegate: MenuButton {
			required property var modelData
			text: modelData.text
			onClicked: {
				if (modelData.isTimezone) {
					root.timezoneSelected(modelData.timezone);
				} else {
					// Emit signal to navigate deeper into this path
					root.pathSelected(modelData.path);
				}
			}
		}
	}
}
