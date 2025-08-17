import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../"
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.speedtest.title")
	property bool showBackButton: true

	property bool testRunning: false
	property string currentStatus: ""
	property real downloadSpeed: 0
	property real uploadSpeed: 0
	property real pingLatency: 0
	property string downloadSpeedText: "---"
	property string uploadSpeedText: "---"
	property string pingLatencyText: "---"

	function formatSpeed(speed) {
		if (speed >= 1000) {
			return (speed / 1000).toFixed(1) + " Gbps";
		} else if (speed >= 1) {
			return speed.toFixed(1) + " Mbps";
		} else {
			return (speed * 1000).toFixed(0) + " Kbps";
		}
	}

	function formatPing(ping) {
		if (ping === null || ping === undefined) {
			return "---";
		}
		return ping.toFixed(0) + " ms";
	}

	function testPing() {
		currentStatus = "Testuji ping...";
		var startTime = Date.now();

		var xhr = new XMLHttpRequest();
		xhr.timeout = 5000; // 5 second timeout for ping

		xhr.onreadystatechange = function () {
			if (xhr.readyState === XMLHttpRequest.DONE) {
				var endTime = Date.now();
				if (xhr.status === 200) {
					pingLatency = endTime - startTime;
					pingLatencyText = formatPing(pingLatency);
					console.log("Ping test successful:", pingLatency + "ms");
				} else {
					pingLatencyText = "Chyba " + xhr.status;
					console.log("Ping test failed with status:", xhr.status);
				}
				testDownload();
			}
		};

		xhr.onerror = function () {
			pingLatencyText = "Chyba sítě";
			console.log("Ping test network error");
			testDownload();
		};

		xhr.ontimeout = function () {
			pingLatencyText = "Timeout";
			console.log("Ping test timeout");
			testDownload();
		};

		// Use simpler ping test endpoint
		xhr.open("GET", "https://1.1.1.1/cdn-cgi/trace?_=" + Date.now(), true); // Cloudflare - fast global network
		xhr.send();
	}

	function testDownload() {
		currentStatus = "Testuji rychlost downloadu...";
		console.log("Starting download test...");
		var startTime = Date.now();
		var totalBytes = 0;
		var testCompleted = false; // Prevent multiple calls
		var xhr = new XMLHttpRequest();
		xhr.timeout = 60000; // 60 second timeout for larger files
		xhr.responseType = "arraybuffer"; // Better for binary data
		xhr.onprogress = function (event) {
			if (event.lengthComputable) {
				totalBytes = event.loaded;
				var currentTime = Date.now();
				var duration = (currentTime - startTime) / 1000;
				if (duration > 0.5) {
					// Wait at least 0.5s for more stable measurement
					var speedBps = totalBytes / duration;
					var speedMbps = (speedBps * 8) / (1024 * 1024);
					downloadSpeedText = formatSpeed(speedMbps) + " (" + Math.round(totalBytes / 1024) + " KB)";
				}
			}
		};

		function finishDownloadTest() {
			if (testCompleted)
				return; // Prevent duplicate calls
			testCompleted = true;
			testUpload();
		}

		xhr.onreadystatechange = function () {
			if (xhr.readyState === XMLHttpRequest.DONE) {
				var endTime = Date.now();
				var duration = (endTime - startTime) / 1000;

				// Try to get response size from different sources
				var responseSize = 0;
				if (xhr.response && xhr.response.byteLength) {
					responseSize = xhr.response.byteLength;
				} else if (xhr.responseText) {
					responseSize = xhr.responseText.length;
				} else if (totalBytes > 0) {
					responseSize = totalBytes;
				}

				console.log("Download test completed. Status:", xhr.status, "Bytes:", responseSize, "Duration:", duration + "s");

				if (xhr.status === 200 && responseSize > 1000 && duration > 0.2) {
					// At least 1KB and 0.2s
					var speedBps = responseSize / duration;
					var speedMbps = (speedBps * 8) / (1024 * 1024);
					downloadSpeed = speedMbps;
					downloadSpeedText = formatSpeed(speedMbps);
					console.log("Download speed:", speedMbps.toFixed(2) + " Mbps");
				} else {
					downloadSpeedText = "Chyba " + xhr.status + " (pouze " + responseSize + " B)";
					console.log("Download test failed - too small or too fast");
				}
				finishDownloadTest();
			}
		};

		xhr.onerror = function () {
			downloadSpeedText = "Chyba sítě";
			console.log("Download test network error");
			finishDownloadTest();
		};

		xhr.ontimeout = function () {
			downloadSpeedText = "Timeout";
			console.log("Download test timeout");
			finishDownloadTest();
		};

		// Use a very fast European server for gigabit testing
		xhr.open("GET", "https://speed.cloudflare.com/__down?bytes=209715200&_=" + Date.now(), true); // 200MB from Cloudflare (very fast global network)
		xhr.send();
	}

	function testUpload() {
		currentStatus = "Testuji rychlost uploadu...";
		console.log("Starting upload test...");

		// Create larger test data for proper gigabit upload testing
		var testData = new Array(100 * 1024 * 1024).join('x'); // 100MB of 'x' characters for upload test
		console.log("Created test data size:", testData.length, "bytes");

		var startTime = Date.now();
		var xhr = new XMLHttpRequest();
		xhr.timeout = 60000; // 60 second timeout for larger files
		var testCompleted = false; // Prevent multiple calls

		// Check if upload events are supported
		if (xhr.upload) {
			xhr.upload.onprogress = function (event) {
				if (event.lengthComputable) {
					var currentTime = Date.now();
					var duration = (currentTime - startTime) / 1000;
					if (duration > 0.3) {
						// Wait at least 0.3s for stable measurement
						var speedBps = event.loaded / duration;
						var speedMbps = (speedBps * 8) / (1024 * 1024);
						uploadSpeedText = formatSpeed(speedMbps) + " (" + Math.round(event.loaded / 1024) + " KB)";
					}
				}
			};
		}

		function finishUploadTest() {
			if (testCompleted)
				return; // Prevent duplicate calls
			testCompleted = true;
			currentStatus = "Test dokončen";
			testRunning = false;
		}

		xhr.onreadystatechange = function () {
			if (xhr.readyState === XMLHttpRequest.DONE) {
				var endTime = Date.now();
				var duration = (endTime - startTime) / 1000;

				console.log("Upload test completed. Status:", xhr.status, "Duration:", duration + "s");

				if (xhr.status === 200 && duration > 0.2) {
					var speedBps = testData.length / duration;
					var speedMbps = (speedBps * 8) / (1024 * 1024);
					uploadSpeed = speedMbps;
					uploadSpeedText = formatSpeed(speedMbps);
					console.log("Upload speed:", speedMbps.toFixed(2) + " Mbps");
				} else {
					uploadSpeedText = "Chyba " + xhr.status;
					console.log("Upload test failed");
				}

				finishUploadTest();
			}
		};

		xhr.onerror = function () {
			uploadSpeedText = "Chyba sítě";
			console.log("Upload test network error");
			finishUploadTest();
		};

		xhr.ontimeout = function () {
			uploadSpeedText = "Timeout";
			console.log("Upload test timeout");
			finishUploadTest();
		};

		// Use Cloudflare upload endpoint for better accuracy
		try {
			xhr.open("POST", "https://speed.cloudflare.com/__up", true);
			xhr.setRequestHeader("Content-Type", "application/octet-stream");
			xhr.send(testData);
		} catch (e) {
			uploadSpeedText = "Chyba sítě";
			console.log("Upload test exception:", e);
			finishUploadTest();
		}
	}

	function startSpeedTest() {
		if (testRunning)
			return;

		testRunning = true;
		currentStatus = "Zahajuji test rychlosti...";
		downloadSpeedText = "---";
		uploadSpeedText = "---";
		pingLatencyText = "---";

		testPing();
	}

	Column {
		anchors.fill: parent
		anchors.margins: 20
		spacing: 20

		// Status
		Rectangle {
			width: parent.width
			height: statusLabel.height + 20
			color: "#34495e"
			radius: 8

			Text {
				id: statusLabel
				anchors.centerIn: parent
				text: currentStatus || "Připraven k testování"
				font.pixelSize: 16
				color: "#ecf0f1"
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
			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: downloadColumn.height + 20
				color: "#2c3e50"
				radius: 8

				Column {
					id: downloadColumn
					anchors.centerIn: parent
					spacing: 8

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: "Download"
						font.pixelSize: 12
						color: "#bdc3c7"
					}

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: downloadSpeedText
						font.pixelSize: 24
						font.bold: true
						color: "#ecf0f1"
					}
				}
			}

			// Upload speed
			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: uploadColumn.height + 20
				color: "#2c3e50"
				radius: 8

				Column {
					id: uploadColumn
					anchors.centerIn: parent
					spacing: 8

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: "Upload"
						font.pixelSize: 12
						color: "#bdc3c7"
					}

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: uploadSpeedText
						font.pixelSize: 24
						font.bold: true
						color: "#ecf0f1"
					}
				}
			}

			// Ping latency (spans both columns)
			Rectangle {
				Layout.fillWidth: true
				Layout.columnSpan: 2
				Layout.preferredHeight: pingColumn.height + 20
				color: "#2c3e50"
				radius: 8

				Column {
					id: pingColumn
					anchors.centerIn: parent
					spacing: 8

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: "Ping"
						font.pixelSize: 12
						color: "#bdc3c7"
					}

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: pingLatencyText
						font.pixelSize: 24
						font.bold: true
						color: "#ecf0f1"
					}
				}
			}
		}

		// Start test button
		Button {
			anchors.horizontalCenter: parent.horizontalCenter
			width: parent.width * 0.8
			height: 50
			text: testRunning ? "Testování..." : "Spustit test"
			enabled: !testRunning

			background: Rectangle {
				color: parent.enabled ? (parent.pressed ? "#27ae60" : "#2ecc71") : "#95a5a6"
				radius: 8
			}

			contentItem: Text {
				text: parent.text
				font.pixelSize: 16
				color: "white"
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
			}

			onClicked: startSpeedTest()
		}

		// Progress indicator
		BusyIndicator {
			anchors.horizontalCenter: parent.horizontalCenter
			visible: testRunning
			running: testRunning
		}

		// Info text
		Text {
			width: parent.width
			text: "Test měří rychlost připojení k internetu. Výsledky se mohou lišit v závislosti na zatížení sítě a serveru."
			font.pixelSize: 12
			color: "#bdc3c7"
			wrapMode: Text.WordWrap
			horizontalAlignment: Text.AlignHCenter
		}
	}
}
