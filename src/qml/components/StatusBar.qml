import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../utils/NodeUtils.js" as Node

Rectangle {
	id: statusBar
	color: Qt.darker(colors.primaryBackground)
	height: window.width * 0.08
	anchors.top: parent.top
	anchors.left: parent.left
	anchors.right: parent.right

	// Properties for connection states
	property int wifiStrength: 0    // WiFi signal strength (0-4)
	property int loraStrength: 0    // LoRa signal strength (0-4)
	property int gsmStrength: 0     // GSM signal strength (0-4)
	property int batteryLevel: 0  // Battery level (0-100)
	property bool hasBattery: false  // Whether device has battery
	property string currentTime: "00:00"

	function navigateTo(pagePath, pageId) {
		if (pagePath && window.currentPageId !== pageId) {
			window.goPage(pagePath, pageId);
		}
	}

	// Function to update current time
	function updateCurrentTime() {
		var now = new Date();
		statusBar.currentTime = Qt.formatTime(now, "hh:mm");
	}

	// Function to update WiFi strength
	function updateWifiStrength() {
		Node.msg("wifiGetCurrentStrength", {}, function (response) {
			if (response.status === 'success') {
				statusBar.wifiStrength = response.data.strength || 0;
			} else {
				statusBar.wifiStrength = 0;
			}
		});
	}

	// Update time
	Timer {
		interval: 1000
		running: true
		repeat: true
		onTriggered: updateCurrentTime()
	}

	// Update WiFi strength periodically
	Timer {
		interval: 5000 // Update every 5 seconds
		running: true
		repeat: true
		onTriggered: updateWifiStrength()
	}

	Component.onCompleted: {
		updateCurrentTime();
		updateWifiStrength();
	}

	// WiFi Rectangle
	SignalIndicator {
		id: wifiRect
		anchors.top: parent.top
		anchors.left: parent.left
		width: statusBar.height * 2
		height: statusBar.height
		signalType: "W"
		signalStrength: statusBar.wifiStrength
		//backgroundColor: "blue"
		pageId: "wifi-settings"
		pagePath: 'Settings/SettingsWiFi.qml'
		onNavigate: statusBar.navigateTo
	}

	// LoRa Rectangle
	SignalIndicator {
		id: loraRect
		anchors.top: parent.top
		anchors.left: wifiRect.right
		width: statusBar.height * 2
		height: statusBar.height
		signalType: "L"
		signalStrength: statusBar.loraStrength
		//backgroundColor: "green"
		pageId: "lora-settings"
		pagePath: 'Settings/SettingsWiFi.qml'  // TODO: change to correct component
		onNavigate: statusBar.navigateTo
	}

	// GSM Rectangle
	SignalIndicator {
		id: gsmRect
		anchors.top: parent.top
		anchors.left: loraRect.right
		width: statusBar.height * 2
		height: statusBar.height
		signalType: "G"
		signalStrength: statusBar.gsmStrength
		//backgroundColor: "orange"
		pageId: "gsm-settings"
		pagePath: 'Settings/SettingsWiFi.qml'  // TODO: change to correct component
		onNavigate: statusBar.navigateTo
	}

	RowLayout {
		anchors.right: parent.right
		anchors.rightMargin: statusBar.height * 0.3
		anchors.verticalCenter: parent.verticalCenter
		spacing: statusBar.height * 0.25

		// Battery (standing) with percentage on the right side, centered including tip
		BatteryIndicator {
			id: battery
			Layout.alignment: Qt.AlignVCenter
			Layout.preferredWidth: statusBar.height * 0.7
			Layout.preferredHeight: statusBar.height * 0.8
			level: statusBar.batteryLevel
			hasBattery: statusBar.hasBattery
			charging: window.batteryManager.charging
		}

		Text {
			text: statusBar.hasBattery ? (statusBar.batteryLevel + "%") : "N/A"
			font.bold: true
			color: colors.primaryForeground
			font.pixelSize: statusBar.height * 0.8
			Layout.alignment: Qt.AlignVCenter
		}

		// Time
		Item {
			Layout.preferredWidth: timeText.width
			Layout.preferredHeight: statusBar.height

			MouseArea {
				anchors.fill: parent
				onClicked: {
					if (window.currentPageId !== "time-settings") {
						window.goPage('Settings/SettingsTime.qml', "time-settings");
					}
				}
				onPressed: timeText.opacity = 0.7
				onReleased: timeText.opacity = 1.0
			}

			Text {
				id: timeText
				text: statusBar.currentTime
				color: colors.primaryForeground
				font.pixelSize: statusBar.height * 0.8
				font.bold: true
				anchors.verticalCenter: parent.verticalCenter
			}
		}
	}
}
