import QtQuick 6.4
import "../static"

Text {
	font.pixelSize: window.width * 0.04
	color: colors.primaryForeground
	wrapMode: Text.WordWrap

	Colors {
		id: colors
	}
}
