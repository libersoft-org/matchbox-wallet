import QtQuick 6.4
import "../static"

Text {
	id: root
	width: parent.width
	font.pixelSize: window.width * 0.04
	color: colors.primaryForeground
	wrapMode: Text.WrapAnywhere

	Colors {
		id: colors
	}
}
