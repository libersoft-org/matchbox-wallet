import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Controls.Material
import "../../components"
import "../../utils/NodeUtils.js" as NodeUtils

Item {
	id: root
	property string title: tr('speedtest.title')
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
		while (bps >= 1024 && unitIndex < units.length - 1) {
			bps /= 1024;
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
		root.currentStatus = tr('speedtest.test_ping');
		//console.log('[SpeedTest] ping start');
		NodeUtils.msg('speedPing', {}, function (res) {
			//console.log('[SpeedTest] ping result', JSON.stringify(res));
			if (res.status === 'success')
				pingLatencyText = formatPing(res.latencyMs);
			else
				pingLatencyText = tr('common.error');
			runDownload();
		});
	}

	function runDownload() {
		root.currentStatus = tr('speedtest.test_download');
		console.log('[SpeedTest] download start');
		NodeUtils.msg('speedDownload', {
			maxSeconds: 5
		}, function (res) {
			console.log('[SpeedTest] download result', JSON.stringify(res));
			if (res.status === 'success')
				root.downloadSpeedText = formatSpeed(res.bytes, res.duration);
			else
				root.downloadSpeedText = tr('common.error');
			runUpload();
		});
	}

	function runUpload() {
		root.currentStatus = tr('speedtest.test_upload');
		//console.log('[SpeedTest] upload start');
		NodeUtils.msg('speedUpload', {
			maxSeconds: 5
		}, function (res) {
			//console.log('[SpeedTest] upload result', JSON.stringify(res));
			if (res.status === 'success')
				uploadSpeedText = formatSpeed(res.bytes, res.duration);
			else
				uploadSpeedText = tr('common.error');
			currentStatus = tr('speedtest.test_completed');
			testRunning = false;
		});
	}

	function startSpeedTest() {
		if (testRunning)
			return;
		testRunning = true;
		currentStatus = tr('speedtest.test_start');
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
			FrameText {
				id: statusLabel
				horizontalAlignment: Text.AlignHCenter
				text: currentStatus || tr('speedtest.test_ready')
				font.bold: true
			}
		}

		// Ping latency (spans both columns)
		Frame {
			FrameColumn {
				id: pingColumn

				FrameText {
					horizontalAlignment: Text.AlignHCenter
					text: tr('speedtest.ping')
					font.bold: true
				}

				FrameText {
					horizontalAlignment: Text.AlignHCenter
					text: pingLatencyText
					font.bold: true
				}
			}
		}

		// Results row
		Row {
			width: parent.width
			spacing: window.width * 0.03

			// Download speed
			Frame {
				width: (parent.width - parent.spacing) / 2

				FrameColumn {
					id: downloadColumn

					FrameText {
						horizontalAlignment: Text.AlignHCenter
						text: tr('speedtest.download')
						font.bold: true
					}

					FrameText {
						horizontalAlignment: Text.AlignHCenter
						text: downloadSpeedText
						font.bold: true
					}
				}
			}

			// Upload speed
			Frame {
				width: (parent.width - parent.spacing) / 2

				FrameColumn {
					id: uploadColumn

					FrameText {
						horizontalAlignment: Text.AlignHCenter
						text: tr('speedtest.upload')
						font.bold: true
					}

					FrameText {
						horizontalAlignment: Text.AlignHCenter
						text: uploadSpeedText
						font.bold: true
					}
				}
			}
		}

		// Start test button
		MenuButton {
			text: tr('speedtest.start')
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
