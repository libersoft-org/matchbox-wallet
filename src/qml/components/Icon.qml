import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
 id: root
 property string img: ""
 property real iconMargins: 0.15

 // Explicitly set implicit size to break binding loops
 implicitWidth: 40
 implicitHeight: 40

 background: Rectangle {
  color: "transparent"
 }

 contentItem: Image {
  anchors.fill: parent
  anchors.margins: parent.height * root.iconMargins
  source: root.img
  fillMode: Image.PreserveAspectFit
  // Use fixed size instead of parent size to avoid binding loops
  sourceSize.width: 64
  sourceSize.height: 64
 }
}
