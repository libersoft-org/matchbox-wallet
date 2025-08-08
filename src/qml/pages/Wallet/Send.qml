import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.wallet.send.title")

	ScrollableContainer {
		anchors.fill: parent

		ColumnLayout {
			width: parent.width
			spacing: 20

			// Recipient address
			ColumnLayout {
				Layout.fillWidth: true
				spacing: 10

				Text {
					text: tr("Recipient Address")
					color: colors.primaryForeground
					font.pixelSize: 16
					font.bold: true
				}

				Rectangle {
					Layout.fillWidth: true
					Layout.preferredHeight: 50
					color: colors.primaryBackground
					border.color: colors.disabledBackground
					border.width: 1
					radius: 5

					TextInput {
						id: addressInput
						anchors.fill: parent
						anchors.margins: 10
						color: colors.primaryForeground
						font.pixelSize: 14
						clip: true
						selectByMouse: true

						Text {
							visible: parent.text === ""
							text: "Enter Bitcoin address..."
							color: colors.disabledForeground
							font: parent.font
							anchors.verticalCenter: parent.verticalCenter
							anchors.left: parent.left
						}
					}
				}

				MenuButton {
					text: tr("Scan QR Code")
					Layout.fillWidth: true
					onClicked: {
						// TODO: Implement QR code scanning
						console.log("Scan QR code clicked");
					}
				}
			}

			// Amount
			ColumnLayout {
				Layout.fillWidth: true
				spacing: 10

				Text {
					text: tr("Amount")
					color: colors.primaryForeground
					font.pixelSize: 16
					font.bold: true
				}

				Rectangle {
					Layout.fillWidth: true
					Layout.preferredHeight: 50
					color: colors.primaryBackground
					border.color: colors.disabledBackground
					border.width: 1
					radius: 5

					TextInput {
						id: amountInput
						anchors.fill: parent
						anchors.margins: 10
						color: colors.primaryForeground
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
							color: colors.disabledForeground
							font: parent.font
							anchors.verticalCenter: parent.verticalCenter
							anchors.left: parent.left
						}
					}
				}
			}

			// Fee
			ColumnLayout {
				Layout.fillWidth: true
				spacing: 10

				Text {
					text: tr("Transaction Fee")
					color: colors.primaryForeground
					font.pixelSize: 16
					font.bold: true
				}

				Rectangle {
					Layout.fillWidth: true
					Layout.preferredHeight: 50
					color: colors.primaryBackground
					border.color: colors.disabledBackground
					border.width: 1
					radius: 5

					Text {
						anchors.centerIn: parent
						text: "0.00001000 BTC (Standard)"
						color: colors.primaryForeground
						font.pixelSize: 14
					}
				}
			}

			// Send button
			MenuButton {
				text: tr("Send Payment")
				Layout.fillWidth: true
				enabled: addressInput.text.length > 0 && amountInput.text.length > 0
				onClicked: {
					// TODO: Implement send payment
					console.log("Send payment:", addressInput.text, amountInput.text);
				}
			}

			Item {
				Layout.preferredHeight: 20
			}
		}
	}
}
