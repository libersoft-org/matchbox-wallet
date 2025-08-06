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
}
