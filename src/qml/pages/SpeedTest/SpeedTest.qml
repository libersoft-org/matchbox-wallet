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
	property string downloadSpeedText: '---'
	property string uploadSpeedText: '---'
	property string pingLatencyText: '---'

	function formatSpeed(bytes, seconds) {
		if (!seconds || seconds <= 0)
			return '0 bps';
		let bps = (bytes * 8) / seconds;
		const units = ['bps', 'kbps', 'Mbps', 'Gbps'];
		let unitIndex = 0;
		while (bps >= 1000 && unitIndex < units.length - 1) {
			bps /= 1000;
			unitIndex++;
		}
		const value = unitIndex === 0 ? Math.round(bps) : bps.toFixed(1);
		return value + ' ' + units[unitIndex];
	}

	function formatPing(ping) {
		if (ping === null || ping === undefined)
			return '---';
		return ping.toFixed(0) + ' ms';
	}

	function runPing() {
		root.currentStatus = tr('menu.speedtest.test_ping');
		//console.log('[SpeedTest] ping start');
		NodeUtils.msg('speedPing', {}, function (res) {
			//console.log('[SpeedTest] ping result', JSON.stringify(res));
			if (res.status === 'success') {
				pingLatencyText = formatPing(res.latencyMs);
			} else {
				pingLatencyText = tr('common.error');
			}
			runDownload();
		});
	}

	function runDownload() {
		root.currentStatus = tr('menu.speedtest.test_download');
		console.log('[SpeedTest] download start');
		NodeUtils.msg('speedDownload', {
			maxSeconds: 5
		}, function (res) {
			console.log('[SpeedTest] download result', JSON.stringify(res));
			if (res.status === 'success') {
				root.downloadSpeedText = formatSpeed(res.bytes, res.duration);
			} else {
				root.downloadSpeedText = tr('common.error');
			}
			runUpload();
		});
	}

	function runUpload() {
		root.currentStatus = tr('menu.speedtest.test_upload');
		//console.log('[SpeedTest] upload start');
		NodeUtils.msg('speedUpload', {
			maxSeconds: 5
		}, function (res) {
			//console.log('[SpeedTest] upload result', JSON.stringify(res));
			if (res.status === 'success') {
				uploadSpeedText = formatSpeed(res.bytes, res.duration);
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
