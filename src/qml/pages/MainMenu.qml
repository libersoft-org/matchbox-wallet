import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../"
import "../components"
import "../utils/NodeUtils.js" as Node

BaseMenu {
	id: root
	title: applicationName
	property bool showBackButton: false

	MenuButton {
		text: tr("menu.wallet.button")
		onClicked: window.goPage('Wallet/Wallet.qml')
	}

	MenuButton {
		text: tr("menu.player.button")
		onClicked: window.goPage('Player/Player.qml')
	}

	MenuButton {
		text: tr("menu.calculator.button")
		onClicked: window.goPage('Calculator/Calculator.qml')
	}

	MenuButton {
		text: tr("menu.settings.button")
		onClicked: window.goPage('Settings/Settings.qml')
	}
	/*
	MenuButton {
		text: "Camera test"
		onClicked: window.goPage('CameraPreview.qml')
	}

	MenuButton {
		text: "Test ping"
		onClicked: {
			Node.msg("testPing", {}, function (result) {
				console.log("Ping result:", JSON.stringify(result));
			});
		}
	}

	MenuButton {
		text: "Delayed ping (2s)"
		onClicked: {
			console.log("Starting delayed ping...");
			Node.msg("testDelayedPing", {
				"delay": 2000
			}, function (result) {
				console.log("Delayed ping result:", JSON.stringify(result));
			});
		}
	}

	MenuButton {
		text: "Test hash"
		onClicked: {
			Node.msg("cryptoHash", {
				"input": "Hello world"
			}, function (result) {
				console.log("Hash result:", JSON.stringify(result));
			});
		}
	}

	MenuButton {
		text: "Generate Key Pair"
		onClicked: {
			Node.msg("cryptoGenerateKeyPair", {}, function (result) {
				console.log("Key pair result:", JSON.stringify(result));
			});
		}
	}

	MenuButton {
		text: "Random Bytes"
		onClicked: {
			Node.msg("cryptoGenerateRandomBytes", {
				"length": 16
			}, function (result) {
				console.log("Random bytes result:", JSON.stringify(result));
			});
		}
	}

	MenuButton {
		text: "Test HMAC"
		onClicked: {
			Node.msg("cryptoHmac", {
				"data": "Hello World",
				"key": "secret_key",
				"algorithm": "sha256"
			}, function (result) {
				console.log("HMAC result:", JSON.stringify(result));
			});
		}
	}

	MenuButton {
		text: "Create Wallet"
		onClicked: {
			Node.msg("cryptoCreateWallet", {}, function (result) {
				console.log("Create wallet result:", JSON.stringify(result));
			});
		}
	}

	MenuButton {
		text: "Validate bad Address"
		onClicked: {
			Node.msg("cryptoValidateAddress", {
				"address": "0x742d35cc6b4C16a5b9C9C9b3dB0B6b1b3b0C5a6e"
			}, function (result) {
				console.log("Validate address result:", JSON.stringify(result));
			});
		}
	}

	MenuButton {
		text: "Validate good Address"
		onClicked: {
			Node.msg("cryptoValidateAddress", {
				"address": "0x39E54b2Ca6535b51333e1Ea4Ef43B4038d23adB4"
			}, function (result) {
				console.log("Validate address result:", JSON.stringify(result));
			});
		}
	}

	MenuButton {
		text: "Get Latest Block"
		onClicked: {
			console.log("Fetching latest block...");
			Node.msg("cryptoGetLatestBlock", {}, function (result) {
				console.log("Latest block result:", JSON.stringify(result));
			});
		}
	}

	MenuButton {
		text: "Get ETH Balance"
		onClicked: {
			console.log("Fetching ETH balance...");
			Node.msg("cryptoGetBalance", {
				"address": "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
			}, function (result) {
				console.log("Balance result:", JSON.stringify(result));
			});
		}
	}

	MenuButton {
		text: "stresstest"
		onClicked: {
			console.log("stresstest...");
			for (let i = 0; i < 1000; i++) {
				Node.msg("audioSetVolume", {
					volume: i % 100
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
		}
	}

	MenuButton {
		text: "wifi"
		onClicked: {
			console.log("Fetching WiFi strength...");
			Node.msg("wifiGetCurrentStrength", {}, function (response) {
				console.log("WiFi strength response:", JSON.stringify(response));
				if (response.status === 'success') {
					console.log("WiFi strength:", response.data.strength);
				} else {
					console.error("Failed to get WiFi strength:", response.message);
				}
			});
		}
	}

	MenuButton {
		text: "crypto2addAddressBookItem"
		onClicked: {
			console.log("Adding address book item...");

			Node.msg("crypto2addAddressBookItem", {
				"address": "0x39E54b2Ca6535b51333e1Ea4Ef43B4038d23adB4",
				"name": "Test Address"
			});
		}
	}

	MenuButton {
		text: "batteryCheckStatus"
		onClicked: {
			console.log("Checking battery status...");
			NodeJS.msg("batteryCheckStatus", {}, function (result) {
				if (result && result.status === "success" && result.data) {
					var data = result.data;
					if (data.batteryLevel !== undefined) {
						batteryLevel = data.batteryLevel;
					}
					if (data.charging !== undefined) {
						charging = data.charging;
					}
					if (data.hasBattery !== undefined) {
						hasBattery = data.hasBattery;
					}
				}
			});
		}
	}
	*/
}
