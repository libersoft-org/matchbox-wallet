import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

BaseMenu {
 id: root
 title: tr("menu.power.title")
 property bool showPowerButton: false

 MenuButton {
  text: tr("menu.power.quit")
  onClicked: Qt.quit()
 }

 MenuButton {
  text: tr("menu.power.reboot")
  onClicked: systemManager.rebootSystem()
 }

 MenuButton {
  text: tr("menu.power.shutdown")
  onClicked: systemManager.shutdownSystem()
 }
}
