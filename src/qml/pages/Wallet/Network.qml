import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("Network Settings")

	ScrollableContainer {
		anchors.fill: parent

		ColumnLayout {
			width: parent.width
			spacing: 20

			// Network selection
			ColumnLayout {
				Layout.fillWidth: true
				spacing: 10

				Text {
					text: tr("Bitcoin Network")
					color: colors.textPrimary
					font.pixelSize: 16
					font.bold: true
				}

				Rectangle {
					Layout.fillWidth: true
					Layout.preferredHeight: 50
					color: colors.backgroundSecondary
					border.color: colors.border
					border.width: 1
					radius: 5

					RowLayout {
						anchors.fill: parent
						anchors.margins: 15

						Text {
							text: "Mainnet"
							color: colors.textPrimary
							font.pixelSize: 14
							Layout.fillWidth: true
						}

						Rectangle {
							width: 12
							height: 12
							radius: 6
							color: "#4CAF50"
						}
					}
				}
			}

			// Connection status
			ColumnLayout {
				Layout.fillWidth: true
				spacing: 10

				Text {
					text: tr("Connection Status")
					color: colors.textPrimary
					font.pixelSize: 16
					font.bold: true
				}

				Rectangle {
					Layout.fillWidth: true
					Layout.preferredHeight: 80
					color: colors.backgroundSecondary
					border.color: colors.border
					border.width: 1
					radius: 8

					ColumnLayout {
						anchors.fill: parent
						anchors.margins: 15
						spacing: 8

						RowLayout {
							Layout.fillWidth: true

							Text {
								text: "Status:"
								color: colors.textSecondary
								font.pixelSize: 14
							}

							Text {
								text: "Connected"
								color: "#4CAF50"
								font.pixelSize: 14
								font.bold: true
							}

							Item {
								Layout.fillWidth: true
							}
						}

						RowLayout {
							Layout.fillWidth: true

							Text {
								text: "Block Height:"
								color: colors.textSecondary
								font.pixelSize: 14
							}

							Text {
								text: "820,543"
								color: colors.textPrimary
								font.pixelSize: 14
							}

							Item {
								Layout.fillWidth: true
							}
						}
					}
				}
			}

			// Node settings
			ColumnLayout {
				Layout.fillWidth: true
				spacing: 10

				Text {
					text: tr("Node Configuration")
					color: colors.textPrimary
					font.pixelSize: 16
					font.bold: true
				}

				Rectangle {
					Layout.fillWidth: true
					Layout.preferredHeight: 50
					color: colors.backgroundSecondary
					border.color: colors.border
					border.width: 1
					radius: 5

					TextInput {
						id: nodeInput
						anchors.fill: parent
						anchors.margins: 10
						color: colors.textPrimary
						font.pixelSize: 14
						clip: true
						selectByMouse: true
						text: "127.0.0.1:8333"

						Text {
							visible: parent.text === ""
							text: "Node address:port"
							color: colors.textSecondary
							font: parent.font
							anchors.verticalCenter: parent.verticalCenter
							anchors.left: parent.left
						}
					}
				}
			}

			// Action buttons
			RowLayout {
				Layout.fillWidth: true
				spacing: 10

				MenuButton {
					text: tr("Reconnect")
					Layout.fillWidth: true
					onClicked: {
						// TODO: Reconnect to network
						console.log("Reconnect clicked");
					}
				}

				MenuButton {
					text: tr("Sync Now")
					Layout.fillWidth: true
					onClicked: {
						// TODO: Force sync
						console.log("Sync now clicked");
					}
				}
			}

			Item {
				Layout.fillHeight: true
			}
		}
	}
}
