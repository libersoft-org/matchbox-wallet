import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
 id: root
 title: tr("menu.settings.title")

 signal systemSettingsRequested
 signal generalSettingsRequested

 MenuButton {
  text: tr("menu.settings.general.button")
  onClicked: root.generalSettingsRequested()
 }

 MenuButton {
  text: tr("menu.settings.wallets.button")
  onClicked: console.log("Wallets settings clicked")
  enabled: false
 }

 MenuButton {
  text: tr("menu.settings.networks.button")
  onClicked: console.log("Networks settings clicked")
  enabled: false
 }

 MenuButton {
  text: tr("menu.settings.system.button")
  onClicked: root.systemSettingsRequested()
 }
}
