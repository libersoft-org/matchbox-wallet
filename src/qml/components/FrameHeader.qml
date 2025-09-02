import QtQuick 6.8
import "../static"

Rectangle {
	property alias text: headerText.text
	property alias textAlignment: headerText.horizontalAlignment

	width: parent.width
	height: headerText.contentHeight + headerText.topPadding + headerText.bottomPadding
	color: colors.primaryForeground
	topLeftRadius: window.width * 0.03
	topRightRadius: window.width * 0.03

	Colors {
		id: colors
	}

	FrameText {
		id: headerText
		anchors.fill: parent
		font.bold: true
		color: colors.primaryBackground
		horizontalAlignment: Text.AlignHCenter
	}
}
