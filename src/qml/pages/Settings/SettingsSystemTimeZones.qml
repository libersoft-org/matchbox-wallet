pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../utils/NodeUtils.js" as NodeUtils

BaseMenu {
	id: root
	title: selectedContinent ? (tr("menu.settings.system.time.timezone") + " - " + selectedContinent) : tr("menu.settings.system.time.timezone")
	signal timezoneSelected(string tz)
	signal continentSelected(string continent)
	property var timezones: []
	property string selectedContinent: ""  // If set, show cities for this continent
	property var displayItems: []

	Component.onCompleted: {
		if (selectedContinent) {
			// We're showing cities for a continent
			extractCitiesForContinent();
		} else {
			// We're showing continents
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
				extractContinents();
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

	function extractContinents() {
		var continentsSet = new Set();

		// Add special cases first
		continentsSet.add("UTC");

		for (var i = 0; i < timezones.length; i++) {
			var timezone = timezones[i];
			if (timezone.includes("/")) {
				var parts = timezone.split("/");
				continentsSet.add(parts[0]);
			}
		}

		// Convert Set to Array, sort and create display items
		var continentsArray = Array.from(continentsSet).sort();
		var items = [];

		for (var j = 0; j < continentsArray.length; j++) {
			var continent = continentsArray[j];
			if (continent === "UTC") {
				items.push({
					text: "UTC",
					isTimezone: true,
					timezone: "UTC"
				});
			} else {
				items.push({
					text: continent,
					isTimezone: false,
					continent: continent
				});
			}
		}

		displayItems = items;
		console.log("Extracted continents:", JSON.stringify(continentsArray));
	}

	function extractCitiesForContinent() {
		var citiesArray = [];

		for (var i = 0; i < timezones.length; i++) {
			var timezone = timezones[i];
			if (timezone.startsWith(selectedContinent + "/")) {
				var parts = timezone.split("/");
				if (parts.length >= 2) {
					// Take everything after the continent as the city name
					var city = parts.slice(1).join("/");
					citiesArray.push({
						text: city.replace(/_/g, " "),
						isTimezone: true,
						timezone: timezone
					});
				}
			}
		}

		// Sort cities by display name
		citiesArray.sort(function (a, b) {
			return a.text.localeCompare(b.text);
		});

		displayItems = citiesArray;
		console.log("Extracted", citiesArray.length, "cities for continent:", selectedContinent);
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
					// Emit signal to navigate to cities for this continent
					root.continentSelected(modelData.continent);
				}
			}
		}
	}
}
