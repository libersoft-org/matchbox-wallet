import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.wallet.addressbook.title")
	
	ColumnLayout {
		anchors.fill: parent
		spacing: 20
		
		// Add address button
		MenuButton {
			text: tr("Add New Address")
			Layout.fillWidth: true
			onClicked: {
				// TODO: Show add address dialog
				console.log("Add new address clicked")
			}
		}
		
		// Address list
		ScrollableContainer {
			Layout.fillWidth: true
			Layout.fillHeight: true
			
			ColumnLayout {
				width: parent.width
				spacing: 10
				
				// Example addresses
				Repeater {
					model: ListModel {
						ListElement {
							name: "Exchange Wallet"
							address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
							note: "Binance withdrawal address"
						}
						ListElement {
							name: "Hardware Wallet"
							address: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"
							note: "Ledger cold storage"
						}
						ListElement {
							name: "Friend's Wallet"
							address: "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa"
							note: "John's Bitcoin address"
						}
					}
					
					delegate: Rectangle {
						Layout.fillWidth: true
						Layout.preferredHeight: 80
						color: Colors.backgroundSecondary
						border.color: Colors.border
						border.width: 1
						radius: 8
						
						RowLayout {
							anchors.fill: parent
							anchors.margins: 15
							spacing: 15
							
							ColumnLayout {
								Layout.fillWidth: true
								spacing: 5
								
								Text {
									text: model.name
									color: Colors.textPrimary
									font.pixelSize: 16
									font.bold: true
								}
								
								Text {
									text: model.address
									color: Colors.textSecondary
									font.pixelSize: 12
									font.family: "monospace"
									Layout.fillWidth: true
									elide: Text.ElideMiddle
								}
								
								Text {
									text: model.note
									color: Colors.textSecondary
									font.pixelSize: 11
									Layout.fillWidth: true
									visible: text.length > 0
								}
							}
							
							ColumnLayout {
								spacing: 5
								
								Button {
									text: "Copy"
									Layout.preferredWidth: 60
									Layout.preferredHeight: 30
									onClicked: {
										// TODO: Copy address to clipboard
										console.log("Copy address:", model.address)
									}
								}
								
								Button {
									text: "Edit"
									Layout.preferredWidth: 60
									Layout.preferredHeight: 30
									onClicked: {
										// TODO: Edit address entry
										console.log("Edit address:", model.name)
									}
								}
							}
						}
					}
				}
				
				// Empty state when no addresses
				Item {
					Layout.fillWidth: true
					Layout.preferredHeight: 100
					visible: false // Show when address list is empty
					
					Text {
						anchors.centerIn: parent
						text: tr("No addresses in your address book")
						color: Colors.textSecondary
						font.pixelSize: 14
					}
				}
			}
		}
	}
}
