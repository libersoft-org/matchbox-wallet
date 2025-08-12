import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../static"

BaseMenu {
	id: root
	title: tr("menu.settings.system.sound.title")

	property int soundVolume: 50

	signal volumeChanged(int volume)

	Column {
		width: parent.width
		spacing: root.height * 0.05

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: tr("menu.settings.system.sound.volume")
			font.pixelSize: root.height * 0.04
			color: colors.primaryForeground
			horizontalAlignment: Text.AlignHCenter
		}

		Range {
			id: volumeRange
			anchors.horizontalCenter: parent.horizontalCenter
			width: parent.width * 0.8
			height: 80
			from: 0
			to: 100
			stepSize: 1
			value: root.soundVolume
			suffix: "%"
			onRangeValueChanged: function (newValue) {
				root.soundVolume = newValue;
				root.volumeChanged(newValue);
			}
		}
	}
}
