import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../static"
import "../../utils/NodeUtils.js" as Node

BaseMenu {
	id: root
	title: tr("menu.settings.display.title")
	property int displayBrightness: 50
	property bool brightnessLoaded: false
	property bool updatingFromSystem: false  // Guard flag
	property string errorMessage: ""
	property bool hasError: false
	property bool loadError: false  // New property for load errors
	signal brightnessChanged(int brightness)

	// Load current brightness when component is loaded
	Component.onCompleted: {
		loadCurrentBrightness();
	}

	function loadCurrentBrightness() {
		console.log("Starting loadCurrentBrightness");
		Node.msg("displayGetBrightness", {}, function (response) {
			console.log("Brightness get response:", JSON.stringify(response));
			if (response.status === 'success' && response.data) {
				var actualBrightness = response.data.brightness || 50;
				console.log("Setting brightness to:", actualBrightness);
				root.updatingFromSystem = true;
				root.displayBrightness = actualBrightness;
				root.brightnessLoaded = true;
				root.loadError = false;
				console.log("Success - loadError set to false");
				root.updatingFromSystem = false;
			} else {
				console.log("Brightness load failed:", response.message || "Unknown error");
				root.updatingFromSystem = true;
				root.displayBrightness = 100; // Set to maximum on error
				root.brightnessLoaded = true;
				root.loadError = true;
				root.errorMessage = response.message || "Failed to load current brightness";
				console.log("Error - loadError set to true, errorMessage:", root.errorMessage);
				root.updatingFromSystem = false;
			}
		});
	}

	function saveBrightness(brightness) {
		root.hasError = false; // Clear previous error
		Node.msg("displaySetBrightness", {
			brightness: brightness
		}, function (response) {
			console.log("Brightness set response:", JSON.stringify(response));
			if (response.status === 'success') {
				console.log("Brightness successfully changed to:", brightness);
				root.hasError = false;
			} else {
				console.error("Failed to change brightness:", response.message || "Unknown error");
				root.errorMessage = response.message || "Failed to set brightness";
				root.hasError = true;
			}
		});
	}

	Column {
		width: parent.width
		spacing: root.height * 0.05

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: tr("menu.settings.display.brightness")
			font.pixelSize: root.height * 0.04
			color: colors.primaryForeground
			horizontalAlignment: Text.AlignHCenter
		}

		Range {
			id: brightnessRange
			anchors.horizontalCenter: parent.horizontalCenter
			width: parent.width * 0.8
			height: 80
			from: 0
			to: 100
			stepSize: 1
			value: root.displayBrightness
			suffix: "%"
			enabled: {
				console.log("Range enabled check - brightnessLoaded:", root.brightnessLoaded, "loadError:", root.loadError);
				return root.brightnessLoaded && !root.loadError;
			}
			opacity: enabled ? 1.0 : 0.5

			onRangeValueChanged: function (newValue) {
				console.log("Range value changed:", newValue, "enabled:", enabled, "loadError:", root.loadError);
				if (root.brightnessLoaded && !root.updatingFromSystem && !root.loadError) {
					root.displayBrightness = newValue;
					root.brightnessChanged(newValue);
					root.saveBrightness(newValue);
				}
			}
		}

		Alert {
			id: brightnessErrorAlert
			anchors.horizontalCenter: parent.horizontalCenter
			width: parent.width * 0.9
			type: "error"
			message: root.errorMessage
			visible: {
				console.log("Alert visibility check - hasError:", root.hasError, "loadError:", root.loadError, "message:", root.errorMessage);
				return root.hasError || root.loadError;
			}
		}

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: root.brightnessLoaded ? "" : tr("common.loading")
			font.pixelSize: root.height * 0.025
			color: colors.disabledForeground
			visible: !root.brightnessLoaded && !root.loadError
		}
	}
}
