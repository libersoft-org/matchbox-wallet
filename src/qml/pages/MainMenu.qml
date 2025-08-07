import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../"
import "../components"

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
   var message = {
    "action": "ping",
    "data": {}
   }
   NodeJS.msg(message, function(result) {
    console.log("Ping result:", JSON.stringify(result))
   })
  }
 }

 MenuButton {
  text: "Test Hash"
  onClicked: {
   var message = {
    "action": "hash",
    "data": {
     "input": "Hello World"
    }
   }
   NodeJS.msg(message, function(result) {
    console.log("Hash result:", JSON.stringify(result))
   })
  }
 }

 MenuButton {
  text: "Generate Key Pair"
  onClicked: {
   var message = {
    "action": "generateKeyPair",
    "data": {}
   }
   NodeJS.msg(message, function(result) {
    console.log("Key pair result:", JSON.stringify(result))
   })
  }
 }

 MenuButton {
  text: "Random Bytes"
  onClicked: {
   var message = {
    "action": "generateRandomBytes",
    "data": {
     "length": 16
    }
   }
   NodeJS.msg(message, function(result) {
    console.log("Random bytes result:", JSON.stringify(result))
   })
  }
 }

 MenuButton {
  text: "Test HMAC"
  onClicked: {
   var message = {
    "action": "hmac",
    "data": {
     "data": "Hello World",
     "key": "secret_key",
     "algorithm": "sha256"
    }
   }
   NodeJS.msg(message, function(result) {
    console.log("HMAC result:", JSON.stringify(result))
   })
  }
 }
}
