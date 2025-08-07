import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
	id: statusBar
	//color: Qt.darker(colors.primaryBackground)
	color: "red"
	height: window.height * 0.075
	anchors.top: parent.top
	anchors.left: parent.left
	anchors.right: parent.right

	// Local alias for easier access to colors
	property var colors: window.colors

	// Properties for connection states
	property int wifiStrength: 0    // WiFi signal strength (0-4)
	property int loraStrength: 0    // LoRa signal strength (0-4)
	property int gsmStrength: 0     // GSM signal strength (0-4)
	property int batteryLevel: 0  // Battery level (0-100)
	property bool hasBattery: false  // Whether device has battery
	property string currentTime: "00:00"

	// Function to update current time
	function updateCurrentTime() {
		var now = new Date();
		statusBar.currentTime = Qt.formatTime(now, "hh:mm");
	}

	// Update time
	Timer {
		interval: 1000
		running: true
		repeat: true
		onTriggered: updateCurrentTime()
	}

	Component.onCompleted: updateCurrentTime()

	// Signal Rectangle Component
	Component {
		id: signalRectComponent
		Rectangle {
			property string signalType: "X"
			property int signalStrength: 0
			property color backgroundColor: "transparent"
			property string pageId: "x-settings"
			property var pageComponent: wifiSettingsPageComponent
			color: backgroundColor

			MouseArea {
				anchors.fill: parent
				onClicked: {
					if (window.currentPageId !== parent.pageId) {
						window.goPage(parent.pageComponent, parent.pageId);
					}
				}
				onPressed: parent.opacity = 0.7
				onReleased: parent.opacity = 1.0
			}

			Row {
				spacing: statusBar.height * 0.1
				width: parent.width * 0.8
				height: parent.height * 0.8

				//anchors.centerIn: parent
				Text {
					text: parent.parent.signalType
					color: colors.primaryForeground
					font.pixelSize: parent.height
					font.bold: true
					anchors.verticalCenter: parent.verticalCenter
				}
				Item {
					width: parent.width
					height: parent.height
					anchors.verticalCenter: parent.verticalCenter

					SignalStrength {
						anchors.fill: parent
						strength: parent.parent.signalStrength
					}

					// Cross for no signal
					CrossOut {
						anchors.fill: parent
						visible: parent.parent.signalStrength === 0
					}
				}
			}
		}
	}

	// Helper component for signal loaders with common properties
	component SignalLoader: Loader {
		sourceComponent: signalRectComponent
		width: statusBar.height * 2
		height: statusBar.height
		anchors.top: parent.top
	}

	// WiFi Rectangle
	SignalLoader {
		id: wifiRect
		anchors.left: parent.left
		onLoaded: {
			item.signalType = "W";
			item.signalStrength = Qt.binding(function () {
					return statusBar.wifiStrength;
				});
			item.backgroundColor = "blue";
			item.pageId = "wifi-settings";
			item.pageComponent = wifiSettingsPageComponent;
		}
	}

	// LoRa Rectangle
	SignalLoader {
		id: loraRect
		anchors.left: wifiRect.right
		onLoaded: {
			item.signalType = "L";
			item.signalStrength = Qt.binding(function () {
					return statusBar.loraStrength;
				});
			item.backgroundColor = "green";
			item.pageId = "lora-settings";
			item.pageComponent = wifiSettingsPageComponent;  // TODO: change to correct component
		}
	}

	// GSM Rectangle
	SignalLoader {
		id: gsmRect
		anchors.left: loraRect.right
		onLoaded: {
			item.signalType = "G";
			item.signalStrength = Qt.binding(function () {
					return statusBar.gsmStrength;
				});
			item.backgroundColor = "orange";
			item.pageId = "gsm-settings";
			item.pageComponent = wifiSettingsPageComponent;  // TODO: change to correct component
		}
	}

	Row {
		anchors.right: parent.right
		anchors.rightMargin: statusBar.height * 0.3
		anchors.verticalCenter: parent.verticalCenter
		spacing: statusBar.height * 0.25

		// Battery icon and percentage
		Row {
			spacing: statusBar.height * 0.15
			anchors.verticalCenter: parent.verticalCenter

			// Battery icon
			Rectangle {
				width: statusBar.height * 0.75
				height: statusBar.height * 0.4
				color: "transparent"
				border.color: "white"
				border.width: Math.max(1, statusBar.height * 0.03)
				radius: statusBar.height * 0.06
				anchors.verticalCenter: parent.verticalCenter

				// Battery tip
				Rectangle {
					width: statusBar.height * 0.06
					height: statusBar.height * 0.2
					color: "white"
					anchors.left: parent.right
					anchors.verticalCenter: parent.verticalCenter
					radius: statusBar.height * 0.03
				}

				// Battery fill
				Rectangle {
					anchors.fill: parent
					anchors.margins: Math.max(1, statusBar.height * 0.06)
					color: statusBar.batteryLevel > 20 ? colors.success : colors.error
					radius: statusBar.height * 0.03
					width: parent.width * (statusBar.batteryLevel / 100.0)
					visible: statusBar.hasBattery
				}

				// Cross for no battery
				CrossOut {
					anchors.fill: parent
					visible: !statusBar.hasBattery
				}
			}

			// Battery percentage
			Text {
				text: statusBar.hasBattery ? statusBar.batteryLevel + "%" : "N/A"
				font.bold: true
				color: colors.primaryForeground
				font.pixelSize: statusBar.height * 0.8
				anchors.verticalCenter: parent.verticalCenter
			}
		}

		// Time
		Item {
			width: timeText.width
			height: statusBar.height

			MouseArea {
				anchors.fill: parent
				onClicked: {
					// Only navigate to time settings if we're not already there
					if (window.currentPageId !== "time-settings") {
						window.goPage(settingsSystemTimePageComponent, "time-settings");
					}
				}
				// Visual feedback
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
