import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

ScrollableContainer {
	id: root
	property string title: tr("menu.wallet.balance.title")

	Column {
		width: parent.width
		spacing: 20

		// Container for balance rectangle and refresh icon
		Row {
			width: parent.width
			height: root.height * 0.1
			spacing: 15

			// Balance display rectangle
			Rectangle {
				width: parent.width - refreshIcon.width - parent.spacing
				height: parent.height
				color: colors.primaryBackground
				radius: height * 0.2
				border.color: colors.primaryForeground
				border.width: 2

				// Balance text
				Text {
					anchors.centerIn: parent
					text: "0.00 ETH"
					color: colors.primaryForeground
					font.pixelSize: parent.height * 0.4
					font.bold: true
				}
			}

			// Refresh icon
			Icon {
				id: refreshIcon
				width: 60
				height: 60
				anchors.verticalCenter: parent.verticalCenter
				img: "qrc:/WalletModule/src/img/refresh.svg"
				iconMargins: 0.1
				onClicked: {
					// TODO: Implement balance refresh
					console.log("Refresh balance clicked");
				}
			}
		}
	}
}
