import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
	id: root
	property string img: ""
	
	width: parent.height
	height: parent.height
	
	background: Rectangle {
		color: "transparent"
	}
	
	contentItem: Image {
		anchors.fill: parent
		anchors.margins: parent.height * 0.15
		source: root.img
		fillMode: Image.PreserveAspectFit
		sourceSize.width: parent.width
		sourceSize.height: parent.height
	}
}
