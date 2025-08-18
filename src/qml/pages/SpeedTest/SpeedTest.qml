import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material
import "../../components"
import "../../utils/NodeUtils.js" as NodeUtils

Item {
	id: root
	property string title: tr('menu.speedtest.title')
	property bool testRunning: false
	property string currentStatus: ''
	property real downloadSpeed: 0
	property real uploadSpeed: 0
	property real pingLatency: 0
	property string downloadSpeedText: '---'
	property string uploadSpeedText: '---'
	property string pingLatencyText: '---'
	property int step: 0
	property bool verbose: true

	function formatSpeed(speed) {
		if (speed >= 1000)
			return (speed / 1000).toFixed(1) + ' Gbps';
		else if (speed >= 1)
			return speed.toFixed(1) + ' Mbps';
		else
			return (speed * 1000).toFixed(0) + ' kbps';
	}

	function formatPing(ping) {
		if (ping === null || ping === undefined)
			return '---';
		return ping.toFixed(0) + ' ms';
	}

	function runPing() {
		root.currentStatus = tr('menu.speedtest.test_ping');
		if (verbose)
			console.log('[SpeedTest] ping start');
		NodeUtils.msg('speedPing', {}, function (res) {
			if (verbose)
				console.log('[SpeedTest] ping result', JSON.stringify(res));
			if (res.status === 'success') {
				pingLatency = res.latencyMs;
				pingLatencyText = formatPing(pingLatency);
			} else {
				pingLatencyText = tr('common.error');
			}
			runDownload();
		});
	}

	function runDownload() {
		root.currentStatus = tr('menu.speedtest.test_download');
		if (verbose)
			console.log('[SpeedTest] download start');
		NodeUtils.msg('speedDownload', {
			maxSeconds: 5
		}, function (res) {
			if (verbose)
				console.log('[SpeedTest] download result', JSON.stringify(res));
			if (res.status === 'success') {
				var mbps = res.mbps || 0;
				downloadSpeed = mbps;
				downloadSpeedText = formatSpeed(mbps / 1); // already Mbps
			} else {
				downloadSpeedText = tr('common.error');
			}
			runUpload();
		});
	}

	function runUpload() {
		root.currentStatus = tr('menu.speedtest.test_upload');
		if (verbose)
			console.log('[SpeedTest] upload start');
		NodeUtils.msg('speedUpload', {
			maxSeconds: 5
		}, function (res) {
			if (verbose)
				console.log('[SpeedTest] upload result', JSON.stringify(res));
			if (res.status === 'success') {
				var mbps = res.mbps || 0;
				uploadSpeed = mbps;
				uploadSpeedText = formatSpeed(mbps / 1);
			} else {
				uploadSpeedText = tr('common.error');
			}
			currentStatus = tr('menu.speedtest.test_completed');
			testRunning = false;
		});
	}

	function startSpeedTest() {
		if (testRunning)
			return;
		testRunning = true;
		currentStatus = tr('menu.speedtest.test_start');
		downloadSpeedText = '---';
		uploadSpeedText = '---';
		pingLatencyText = '---';

		runPing();
	}

	Column {
		anchors.fill: parent
		anchors.margins: window.width * 0.05
		spacing: window.width * 0.03

		// Status
		Frame {
			width: parent.width
			height: statusLabel.implicitHeight + (window.width * 0.03)

			Text {
				id: statusLabel
				anchors.centerIn: parent
				text: currentStatus || tr('menu.speedtest.test_ready')
				font.pixelSize: window.width * 0.04
				font.bold: true
				color: colors.primaryForeground
				wrapMode: Text.WordWrap
			}
		}

		// Ping latency (spans both columns)
		Frame {
			width: parent.width
			height: pingColumn.implicitHeight + (window.width * 0.03)

			Column {
				id: pingColumn
				anchors.centerIn: parent
				spacing: window.width * 0.01

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: tr('menu.speedtest.ping')
					font.pixelSize: window.width * 0.04
					font.bold: true
					color: colors.primaryForeground
				}

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: pingLatencyText
					font.pixelSize: window.width * 0.06
					font.bold: true
					color: colors.primaryForeground
				}
			}
		}

		// Results grid
		GridLayout {
			width: parent.width
			columns: 2
			rowSpacing: window.width * 0.03
			columnSpacing: window.width * 0.03

			// Download speed
			Frame {
				Layout.fillWidth: true
				Layout.preferredHeight: downloadColumn.implicitHeight + (window.width * 0.03)

				Column {
					id: downloadColumn
					anchors.centerIn: parent
					spacing: window.width * 0.01

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: tr('menu.speedtest.download')
						font.pixelSize: window.width * 0.04
						font.bold: true
						color: colors.primaryForeground
					}

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: downloadSpeedText
						font.pixelSize: window.width * 0.06
						font.bold: true
						color: colors.primaryForeground
					}
				}
			}

			// Upload speed
			Frame {
				Layout.fillWidth: true
				Layout.preferredHeight: uploadColumn.implicitHeight + (window.width * 0.03)

				Column {
					id: uploadColumn
					anchors.centerIn: parent
					spacing: window.width * 0.01

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: tr('menu.speedtest.upload')
						font.pixelSize: window.width * 0.04
						font.bold: true
						color: colors.primaryForeground
					}

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: uploadSpeedText
						font.pixelSize: window.width * 0.06
						font.bold: true
						color: colors.primaryForeground
					}
				}
			}
		}

		// Start test button
		MenuButton {
			text: tr('menu.speedtest.start')
			enabled: !testRunning
			onClicked: startSpeedTest()
		}

		// Progress indicator
		BusyIndicator {
			anchors.horizontalCenter: parent.horizontalCenter
			visible: testRunning
			running: testRunning
			Material.accent: 'blue'
		}
	}
}
