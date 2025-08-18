import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material
import "../../components"

BaseMenu {
	id: root
	title: tr('menu.speedtest.title')
	property bool showBackButton: true

	property bool testRunning: false
	property string currentStatus: ''
	property real downloadSpeed: 0
	property real uploadSpeed: 0
	property real pingLatency: 0
	property string downloadSpeedText: '---'
	property string uploadSpeedText: '---'
	property string pingLatencyText: '---'

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

	function testPing() {
		currentStatus = tr('menu.speedtest.test_ping');
		var startTime = Date.now();
		var xhr = new XMLHttpRequest();
		xhr.timeout = 5000;
		xhr.onreadystatechange = function () {
			if (xhr.readyState === XMLHttpRequest.DONE) {
				var endTime = Date.now();
				if (xhr.status === 200) {
					pingLatency = endTime - startTime;
					pingLatencyText = formatPing(pingLatency);
					console.log('Ping test successful:', pingLatency + 'ms');
				} else {
					pingLatencyText = tr('common.error') + ': ' + xhr.status;
					console.log('Ping test failed with status:', xhr.status);
				}
				testDownload();
			}
		};
		xhr.onerror = function () {
			pingLatencyText = tr('menu.speedtest.network_error') + ': ' + xhr.status;
			console.log('Ping test network error');
			testDownload();
		};
		xhr.ontimeout = function () {
			pingLatencyText = tr('menu.speedtest.timeout');
			console.log('Ping test timeout');
			testDownload();
		};
		xhr.open('GET', 'https://1.1.1.1/cdn-cgi/trace?_=' + Date.now(), true);
		xhr.send();
	}

	function testDownload() {
		currentStatus = tr('menu.speedtest.test_download');
		console.log('Starting download test...');
		var startTime = Date.now();
		var totalBytes = 0;
		var testCompleted = false;
		var xhr = new XMLHttpRequest();
		xhr.timeout = 5000;
		xhr.responseType = 'arraybuffer';
		xhr.onprogress = function (event) {
			if (event.lengthComputable) {
				totalBytes = event.loaded;
				var currentTime = Date.now();
				var duration = (currentTime - startTime) / 1000;
				if (duration > 0.5) {
					// Wait at least 0.5s for more stable measurement
					var speedBps = totalBytes / duration;
					var speedMbps = (speedBps * 8) / (1024 * 1024);
					downloadSpeedText = formatSpeed(speedMbps) + ' (' + Math.round(totalBytes / 1024) + ' kB)';
				}
			}
		};

		function finishDownloadTest() {
			if (testCompleted)
				return;
			testCompleted = true;
			testUpload();
		}

		xhr.onreadystatechange = function () {
			if (xhr.readyState === XMLHttpRequest.DONE) {
				var endTime = Date.now();
				var duration = (endTime - startTime) / 1000;
				var responseSize = 0;
				if (xhr.response && xhr.response.byteLength)
					responseSize = xhr.response.byteLength;
				else if (xhr.responseText)
					responseSize = xhr.responseText.length;
				else if (totalBytes > 0)
					responseSize = totalBytes;
				console.log('Download test completed. Status:', xhr.status, 'Bytes:', responseSize, 'Duration:', duration + 's');
				if (xhr.status === 200 && responseSize > 1000 && duration > 0.2) {
					// At least 1KB and 0.2s
					var speedBps = responseSize / duration;
					var speedMbps = (speedBps * 8) / (1024 * 1024);
					downloadSpeed = speedMbps;
					downloadSpeedText = formatSpeed(speedMbps);
					console.log('Download speed:', speedMbps.toFixed(2) + ' Mbps');
				} else {
					downloadSpeedText = tr('common.error') + ': ' + xhr.status + ' (' + responseSize + ' B)';
					console.log('Download test failed - too small or too fast');
				}
				finishDownloadTest();
			}
		};
		xhr.onerror = function () {
			downloadSpeedText = tr('menu.speedtest.network_error');
			console.log('Download test network error');
			finishDownloadTest();
		};
		xhr.ontimeout = function () {
			downloadSpeedText = tr('menu.speedtest.timeout');
			console.log('Download test timeout');
			finishDownloadTest();
		};
		xhr.open('GET', 'https://speed.cloudflare.com/__down?bytes=104857600&_=' + Date.now(), true); // 100MB
		xhr.send();
	}

	function testUpload() {
		currentStatus = tr('menu.speedtest.test_upload');
		console.log('Starting upload test...');
		var testData = new Array(100 * 1024 * 1024).join('x'); // 100MB of 'x' characters for upload test
		console.log('Created test data size:', testData.length, 'bytes');
		var startTime = Date.now();
		var xhr = new XMLHttpRequest();
		xhr.timeout = 5000;
		var testCompleted = false;
		if (xhr.upload) {
			xhr.upload.onprogress = function (event) {
				if (event.lengthComputable) {
					var currentTime = Date.now();
					var duration = (currentTime - startTime) / 1000;
					if (duration > 0.3) {
						var speedBps = event.loaded / duration;
						var speedMbps = (speedBps * 8) / (1024 * 1024);
						uploadSpeedText = formatSpeed(speedMbps) + ' (' + Math.round(event.loaded / 1024) + ' KB)';
					}
				}
			};
		}

		function finishUploadTest() {
			if (testCompleted)
				return;
			testCompleted = true;
			currentStatus = tr('menu.speedtest.test_completed');
			testRunning = false;
		}

		xhr.onreadystatechange = function () {
			if (xhr.readyState === XMLHttpRequest.DONE) {
				var endTime = Date.now();
				var duration = (endTime - startTime) / 1000;
				console.log('Upload test completed. Status:', xhr.status, 'Duration:', duration + 's');
				if (xhr.status === 200 && duration > 0.2) {
					var speedBps = testData.length / duration;
					var speedMbps = (speedBps * 8) / (1024 * 1024);
					uploadSpeed = speedMbps;
					uploadSpeedText = formatSpeed(speedMbps);
					console.log('Upload speed:', speedMbps.toFixed(2) + ' Mbps');
				} else {
					uploadSpeedText = tr('common.error') + ': ' + xhr.status;
					console.log('Upload test failed');
				}
				finishUploadTest();
			}
		};
		xhr.onerror = function () {
			uploadSpeedText = tr('menu.speedtest.network_error');
			console.log('Upload test network error');
			finishUploadTest();
		};
		xhr.ontimeout = function () {
			uploadSpeedText = tr('menu.speedtest.timeout');
			console.log('Upload test timeout');
			finishUploadTest();
		};
		try {
			xhr.open('POST', 'https://speed.cloudflare.com/__up', true);
			xhr.setRequestHeader('Content-Type', 'application/octet-stream');
			xhr.send(testData);
		} catch (e) {
			uploadSpeedText = tr('menu.speedtest.network_error');
			console.log('Upload test exception:', e);
			finishUploadTest();
		}
	}

	function startSpeedTest() {
		if (testRunning)
			return;
		testRunning = true;
		currentStatus = tr('menu.speedtest.test_start');
		downloadSpeedText = '---';
		uploadSpeedText = '---';
		pingLatencyText = '---';
		testPing();
	}

	Column {
		anchors.fill: parent
		anchors.margins: 20
		spacing: 20

		// Status
		Frame {
			width: parent.width
			height: window.width * 0.1
			borderRadius: window.width * 0.02

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

		// Results grid
		GridLayout {
			width: parent.width
			columns: 2
			rowSpacing: 15
			columnSpacing: 15

			// Download speed
			Frame {
				Layout.fillWidth: true
				Layout.preferredHeight: downloadColumn.height + 20

				Column {
					id: downloadColumn
					anchors.centerIn: parent
					spacing: window.width * 0.02

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: tr('menu.speedtest.download')
						font.pixelSize: window.width * 0.02
						font.bold: true
						color: colors.primaryForeground
					}

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: downloadSpeedText
						font.pixelSize: window.width * 0.04
						font.bold: true
						color: colors.primaryForeground
					}
				}
			}

			// Upload speed
			Frame {
				Layout.fillWidth: true
				Layout.preferredHeight: uploadColumn.height + 20

				Column {
					id: uploadColumn
					anchors.centerIn: parent
					spacing: 8

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: 'Upload'
						font.pixelSize: 12
						color: colors.primaryForeground
					}

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: uploadSpeedText
						font.pixelSize: 24
						font.bold: true
						color: colors.primaryForeground
					}
				}
			}

			// Ping latency (spans both columns)
			Frame {
				Layout.fillWidth: true
				Layout.columnSpan: 2
				Layout.preferredHeight: pingColumn.height + 20

				Column {
					id: pingColumn
					anchors.centerIn: parent
					spacing: 8

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: 'Ping'
						font.pixelSize: 12
						color: colors.primaryForeground
					}

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: pingLatencyText
						font.pixelSize: 24
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
