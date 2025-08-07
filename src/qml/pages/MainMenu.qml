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
   Node.msg("ping", {}, function(result) {
    console.log("Ping result:", JSON.stringify(result))
   })
  }
 }

 MenuButton {
  text: "Test Hash"
  onClicked: {
   Node.msg("hash", {"input": "Hello World"}, function(result) {
    console.log("Hash result:", JSON.stringify(result))
   })
  }
 }

 MenuButton {
  text: "Generate Key Pair"
  onClicked: {
   Node.msg("generateKeyPair", {}, function(result) {
    console.log("Key pair result:", JSON.stringify(result))
   })
  }
 }

 MenuButton {
  text: "Random Bytes"
  onClicked: {
   Node.msg("generateRandomBytes", {"length": 16}, function(result) {
    console.log("Random bytes result:", JSON.stringify(result))
   })
  }
 }

 MenuButton {
  text: "Test HMAC"  
  onClicked: {
   Node.msg("hmac", {"data": "Hello World", "key": "secret_key", "algorithm": "sha256"}, function(result) {
    console.log("HMAC result:", JSON.stringify(result))
   })
  }
 }
}
