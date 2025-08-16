import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../static"
import "../../utils/NodeUtils.js" as Node

BaseMenu {
	id: root
	title: tr("menu.settings.sound.title")
	property int soundVolume: 0
	property bool volumeLoaded: false
	property bool updatingFromSystem: false  // Guard flag
	property string errorMessage: ""
	property bool hasError: false
	property bool isMuted: false
	property int volumeBeforeMute: 0
	signal volumeChanged(int volume)

	// Load current volume when component is loaded
	Component.onCompleted: {
		loadCurrentVolume();
	}

	function loadCurrentVolume() {
		Node.msg("audioGetVolume", {}, function (response) {
			console.log("Volume get response:", JSON.stringify(response));
			if (response.status === 'success' && response.data) {
				var actualVolume = response.data.volume || 0;
				console.log("Setting volume to:", actualVolume);
				root.updatingFromSystem = true;
				root.soundVolume = actualVolume;
				// If volume is 0, consider it as muted (but don't set volumeBeforeMute)
				if (actualVolume === 0) {
					root.isMuted = true;
					// Set a default previous volume if none exists
					if (root.volumeBeforeMute === 0)
						root.volumeBeforeMute = 50;
				} else
					root.isMuted = false;
				root.volumeLoaded = true;
				root.updatingFromSystem = false;
			} else {
				console.log("Volume load failed, using default 0");
				root.updatingFromSystem = true;
				root.soundVolume = 0;
				root.isMuted = true;
				root.volumeBeforeMute = 50; // Default volume when unmuting
				root.volumeLoaded = true;
				root.updatingFromSystem = false;
			}
		});
	}

	function saveVolume(volume) {
		root.hasError = false;
		Node.msg("audioSetVolume", {
			volume: volume
		}, function (response) {
			console.log("Volume set response:", JSON.stringify(response));
			if (response.status === 'success') {
				console.log("Volume successfully changed to:", volume);
				root.hasError = false;
			} else {
				console.error("Failed to change volume:", response.message || "Unknown error");
				root.errorMessage = response.message || "Failed to set volume";
				root.hasError = true;
			}
		});
	}

	function toggleMute() {
		if (root.isMuted) {
			// Unmute - restore previous volume
			root.isMuted = false;
			root.soundVolume = root.volumeBeforeMute;
			root.saveVolume(root.volumeBeforeMute);
		} else {
			// Mute - save current volume and set to 0
			root.volumeBeforeMute = root.soundVolume;
			root.isMuted = true;
			root.soundVolume = 0;
			root.saveVolume(0);
		}
	}

	Column {
		width: parent.width
		spacing: root.height * 0.05

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: tr("menu.settings.sound.volume")
			font.pixelSize: root.height * 0.04
			color: colors.primaryForeground
			horizontalAlignment: Text.AlignHCenter
		}

		MenuButton {
			id: muteButton
			anchors.horizontalCenter: parent.horizontalCenter
			width: parent.width * 0.6
			height: root.height * 0.08
			text: root.isMuted ? tr("menu.settings.sound.unmute") : tr("menu.settings.sound.mute")
			enabled: root.volumeLoaded
			opacity: root.volumeLoaded ? 1.0 : 0.5
			onClicked: root.toggleMute()
		}

		Range {
			id: volumeRange
			anchors.horizontalCenter: parent.horizontalCenter
			width: parent.width * 0.8
			height: 80
			from: 0
			to: 100
			stepSize: 1
			value: root.soundVolume  // Direct binding to soundVolume
			suffix: "%"
			enabled: root.volumeLoaded && !root.isMuted
			opacity: (root.volumeLoaded && !root.isMuted) ? 1.0 : 0.5
			onRangeValueChanged: function (newValue) {
				if (root.volumeLoaded && !root.updatingFromSystem && !root.isMuted) {
					root.soundVolume = newValue;
					root.volumeChanged(newValue);
					root.saveVolume(newValue);
				}
			}
		}

		Alert {
			id: volumeErrorAlert
			anchors.horizontalCenter: parent.horizontalCenter
			width: parent.width * 0.9
			type: "error"
			message: root.errorMessage
			visible: root.hasError
		}

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: root.volumeLoaded ? "" : tr("common.loading")
			font.pixelSize: root.height * 0.025
			color: colors.disabledForeground
			visible: !root.volumeLoaded
		}
	}
}
