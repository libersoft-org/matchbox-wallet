import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("Wallet Addresses")

	ColumnLayout {
		anchors.fill: parent
		spacing: 20

		// Generate new address button
		MenuButton {
			text: tr("Generate New Address")
			Layout.fillWidth: true
			onClicked: {
				// TODO: Generate new address
				console.log("Generate new address clicked");
			}
		}

		// Address list
		ScrollableContainer {
			Layout.fillWidth: true
			Layout.fillHeight: true

			ColumnLayout {
				width: parent.width
				spacing: 10

				Text {
					text: tr("Your Addresses")
					color: Colors.textPrimary
					font.pixelSize: 16
					font.bold: true
				}

				// Example addresses
				Repeater {
					model: ListModel {
						ListElement {
							address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
							balance: "0.00000000"
							used: false
							index: 0
						}
						ListElement {
							address: "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq"
							balance: "0.00015000"
							used: true
							index: 1
						}
						ListElement {
							address: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
							balance: "0.00000000"
							used: true
							index: 2
						}
					}

					delegate: Rectangle {
						Layout.fillWidth: true
						Layout.preferredHeight: 90
						color: Colors.backgroundSecondary
						border.color: model.used ? Colors.border : "#4CAF50"
						border.width: 1
						radius: 8

						ColumnLayout {
							anchors.fill: parent
							anchors.margins: 15
							spacing: 8

							RowLayout {
								Layout.fillWidth: true

								Text {
									text: "Address #" + (model.index + 1)
									color: Colors.textPrimary
									font.pixelSize: 14
									font.bold: true
								}

								Item {
									Layout.fillWidth: true
								}

								Rectangle {
									width: 8
									height: 8
									radius: 4
									color: model.used ? "#FFC107" : "#4CAF50"
								}

								Text {
									text: model.used ? "Used" : "Fresh"
									color: Colors.textSecondary
									font.pixelSize: 12
								}
							}

							Text {
								text: model.address
								color: Colors.textSecondary
								font.pixelSize: 11
								font.family: "monospace"
								Layout.fillWidth: true
								elide: Text.ElideMiddle
							}

							RowLayout {
								Layout.fillWidth: true

								Text {
									text: "Balance: " + model.balance + " BTC"
									color: Colors.textPrimary
									font.pixelSize: 12
								}

								Item {
									Layout.fillWidth: true
								}

								Button {
									text: "Copy"
									Layout.preferredWidth: 50
									Layout.preferredHeight: 25
									onClicked: {
										// TODO: Copy address to clipboard
										console.log("Copy address:", model.address);
									}
								}

								Button {
									text: "QR"
									Layout.preferredWidth: 35
									Layout.preferredHeight: 25
									onClicked: {
										// TODO: Show QR code
										console.log("Show QR for:", model.address);
									}
								}
							}
						}
					}
				}

				Text {
					text: tr("Fresh addresses haven't been used for receiving payments yet")
					color: Colors.textSecondary
					font.pixelSize: 11
					Layout.fillWidth: true
					wrapMode: Text.WordWrap
					Layout.topMargin: 10
				}
			}
		}
	}
}
