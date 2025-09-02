import QtQuick 6.4
import "../static"

Rectangle {
	property alias text: headerText.text
	property alias textAlignment: headerText.horizontalAlignment

	width: parent.width
	height: headerText.contentHeight + headerText.topPadding + headerText.bottomPadding
	color: colors.primaryForeground

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
