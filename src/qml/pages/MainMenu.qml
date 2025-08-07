import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../"
import "../components"
import "../utils/NodeUtils.js" as Node

BaseMenu {
	id: root
	title: tr("menu.title")
	property bool showBackButton: false
	property var walletComponent
	property var settingsComponent
	property var powerOffComponent
	property var cameraPreviewComponent
	property var goPageFunction

	MenuButton {
		text: tr("menu.wallet.button")
		onClicked: goPageFunction(walletComponent)
	}

	MenuButton {
		text: tr("menu.settings.button")
		onClicked: goPageFunction(settingsComponent)
	}

	MenuButton {
		text: "Camera test"
		onClicked: goPageFunction(cameraPreviewComponent)
	}

	MenuButton {
		text: "Test Ping"
		onClicked: {
			Node.msg("ping", {}, function (result) {
					console.log("Ping result:", JSON.stringify(result));
				});
		}
	}

	MenuButton {
		text: "Test Hash"
		onClicked: {
			Node.msg("hash", {
					"input": "Hello World"
				}, function (result) {
					console.log("Hash result:", JSON.stringify(result));
				});
		}
	}

	MenuButton {
		text: "Generate Key Pair"
		onClicked: {
			Node.msg("generateKeyPair", {}, function (result) {
					console.log("Key pair result:", JSON.stringify(result));
				});
		}
	}

	MenuButton {
		text: "Random Bytes"
		onClicked: {
			Node.msg("generateRandomBytes", {
					"length": 16
				}, function (result) {
					console.log("Random bytes result:", JSON.stringify(result));
				});
		}
	}

	MenuButton {
		text: "Test HMAC"
		onClicked: {
			Node.msg("hmac", {
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
			Node.msg("createWallet", {}, function (result) {
					console.log("Create wallet result:", JSON.stringify(result));
				});
		}
	}

	MenuButton {
		text: "Validate bad Address"
		onClicked: {
			Node.msg("validateAddress", {
					"address": "0x742d35cc6b4C16a5b9C9C9b3dB0B6b1b3b0C5a6e"
				}, function (result) {
					console.log("Validate address result:", JSON.stringify(result));
				});
		}
	}

	MenuButton {
		text: "Validate good Address"
		onClicked: {
			Node.msg("validateAddress", {
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
			Node.msg("getLatestBlock", {}, function (result) {
					console.log("Latest block result:", JSON.stringify(result));
				});
		}
	}

	MenuButton {
		text: "Get ETH Balance"
		onClicked: {
			console.log("Fetching ETH balance...");
			Node.msg("getBalance", {
					"address": "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
				}, function (result) {
					console.log("Balance result:", JSON.stringify(result));
				});
		}
	}
}
