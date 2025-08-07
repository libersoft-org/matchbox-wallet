import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.wallet.receive.title")

	ScrollableContainer {
		anchors.fill: parent

		ColumnLayout {
			width: parent.width
			spacing: 20

			// Current address display
			ColumnLayout {
				Layout.fillWidth: true
				spacing: 10

				Text {
					text: tr("Your Bitcoin Address")
					color: Colors.textPrimary
					font.pixelSize: 16
					font.bold: true
				}

				Rectangle {
					Layout.fillWidth: true
					Layout.preferredHeight: 120
					color: Colors.backgroundSecondary
					border.color: Colors.border
					border.width: 1
					radius: 10

					ColumnLayout {
						anchors.fill: parent
						anchors.margins: 15
						spacing: 10

						// QR Code placeholder
						Rectangle {
							Layout.preferredWidth: 80
							Layout.preferredHeight: 80
							Layout.alignment: Qt.AlignHCenter
							color: Colors.background
							border.color: Colors.border
							border.width: 1
							radius: 5

							Text {
								anchors.centerIn: parent
								text: "QR"
								color: Colors.textSecondary
								font.pixelSize: 12
							}
						}

						Text {
							id: addressText
							text: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
							color: Colors.textPrimary
							font.pixelSize: 12
							font.family: "monospace"
							Layout.alignment: Qt.AlignHCenter
							wrapMode: Text.WrapAnywhere
							Layout.fillWidth: true
							horizontalAlignment: Text.AlignHCenter
						}
					}
				}

				RowLayout {
					Layout.fillWidth: true
					spacing: 10

					MenuButton {
						text: tr("Copy Address")
						Layout.fillWidth: true
						onClicked: {
							// TODO: Copy address to clipboard
							console.log("Copy address clicked");
						}
					}

					MenuButton {
						text: tr("New Address")
						Layout.fillWidth: true
						onClicked: {
							// TODO: Generate new address
							console.log("New address clicked");
						}
					}
				}
			}

			// Amount request (optional)
			ColumnLayout {
				Layout.fillWidth: true
				spacing: 10

				Text {
					text: tr("Request Amount (Optional)")
					color: Colors.textPrimary
					font.pixelSize: 16
					font.bold: true
				}

				Rectangle {
					Layout.fillWidth: true
					Layout.preferredHeight: 50
					color: Colors.backgroundSecondary
					border.color: Colors.border
					border.width: 1
					radius: 5

					TextInput {
						id: requestAmountInput
						anchors.fill: parent
						anchors.margins: 10
						color: Colors.textPrimary
						font.pixelSize: 14
						clip: true
						selectByMouse: true
						validator: DoubleValidator {
							bottom: 0
							decimals: 8
						}

						Text {
							visible: parent.text === ""
							text: "0.00000000"
							color: Colors.textSecondary
							font: parent.font
							anchors.verticalCenter: parent.verticalCenter
							anchors.left: parent.left
						}
					}
				}
			}

			// Generate payment request
			MenuButton {
				text: tr("Generate Payment Request")
				Layout.fillWidth: true
				onClicked: {
					// TODO: Generate payment request with amount
					console.log("Generate payment request:", requestAmountInput.text);
				}
			}

			Item {
				Layout.fillHeight: true
			}
		}
	}
}
