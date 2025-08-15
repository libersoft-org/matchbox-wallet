import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"
import "../../utils/NodeUtils.js" as Node

Rectangle {
	id: root
	color: colors.primaryBackground
	property string title: tr("menu.wallet.addressbook.title")
	
	property var addressBookItems: []
	property bool isLoading: false
	property string editingItemGuid: ""
	property bool showAddDialog: false
	property bool showEditDialog: false
	property bool showDeleteDialog: false
	property string deleteItemGuid: ""
	property string deleteItemName: ""
	
	Connections {
		target: window.eventManager
		function onEventReceived(eventType, data) {
			switch(eventType) {
				case "crypto2.addressBook.subscribe":
					console.log("Address book updated:", data)
					loadAddressBook()
					break
			}
		}
	}
	
	Component.onCompleted: {
		loadAddressBook()
	}
	
	function loadAddressBook() {
		isLoading = true
		Node.msg("crypto2getAddressBookItems", {}, function(response) {
			console.log("Address book items:", JSON.stringify(response, null, 2))
			addressBookItems = response.data || []
			isLoading = false
		})
	}
	
	function addAddressBookItem(name, address) {
		Node.msg("crypto2addAddressBookItem", {
			name: name,
			address: address
		}, function(response) {
			console.log("Add address book item response:", JSON.stringify(response, null, 2))
			if (response.isValid) {
				showAddDialog = false
				loadAddressBook()
			} else {
				addDialog.errorMessage = response.error || "Failed to add item"
			}
		})
	}
	
	function editAddressBookItem(itemGuid, name, address) {
		Node.msg("crypto2editAddressBookItem", {
			itemGuid: itemGuid,
			name: name,
			address: address
		}, function(response) {
			console.log("Edit address book item response:", response)
			if (response.isValid) {
				showEditDialog = false
				editingItemGuid = ""
				loadAddressBook()
			} else {
				editDialog.errorMessage = response.error || "Failed to edit item"
			}
		})
	}
	
	function deleteAddressBookItem(itemGuid) {
		Node.msg("crypto2deleteAddressBookItem", {
			itemGuid: itemGuid
		}, function(response) {
			console.log("Delete address book item response:", response)
			showDeleteDialog = false
			deleteItemGuid = ""
			deleteItemName = ""
			loadAddressBook()
		})
	}
	
	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 20
		spacing: 20
		
		RowLayout {
			Layout.fillWidth: true
			
			Text {
				text: root.title
				font.pixelSize: 24
				font.bold: true
				color: colors.primaryText
				Layout.fillWidth: true
			}
			
			Button {
				text: "+"
				font.pixelSize: 20
				width: 40
				height: 40
				onClicked: {
					showAddDialog = true
				}
			}
		}
		
		Rectangle {
			Layout.fillWidth: true
			Layout.fillHeight: true
			color: colors.secondaryBackground
			border.color: colors.border
			border.width: 1
			radius: 8
			
			ScrollView {
				anchors.fill: parent
				anchors.margins: 10
				
				ListView {
					id: listView
					model: addressBookItems
					spacing: 10
					
					delegate: Rectangle {
						width: listView.width
						height: 80
						color: colors.primaryBackground
						border.color: colors.border
						border.width: 1
						radius: 4
						
						RowLayout {
							anchors.fill: parent
							anchors.margins: 15
							spacing: 10
							
							Column {
								Layout.fillWidth: true
								spacing: 5
								
								Text {
									text: modelData.name || "Unnamed"
									font.pixelSize: 16
									font.bold: true
									color: colors.primaryText
									wrapMode: Text.Wrap
								}
								
								Text {
									text: modelData.address || ""
									font.pixelSize: 12
									color: colors.secondaryText
									wrapMode: Text.Wrap
									width: parent.width
								}
							}
							
							Button {
								text: tr("common.edit")
								width: 60
								height: 30
								onClicked: {
									editingItemGuid = modelData.guid
									editDialog.nameField = modelData.name
									editDialog.addressField = modelData.address
									showEditDialog = true
								}
							}
							
							Button {
								text: tr("common.delete")
								width: 60
								height: 30
								onClicked: {
									deleteItemGuid = modelData.guid
									deleteItemName = modelData.name || "Unnamed"
									showDeleteDialog = true
								}
							}
						}
					}
					
					Text {
						anchors.centerIn: parent
						text: isLoading ? tr("common.loading") : (addressBookItems.length === 0 ? tr("menu.wallet.addressbook.empty") : "")
						color: colors.secondaryText
						font.pixelSize: 16
						visible: isLoading || addressBookItems.length === 0
					}
				}
			}
		}
	}
	
	Dialog {
		id: addDialog
		modal: true
		anchors.centerIn: parent
		width: Math.min(400, parent.width - 40)
		height: 300
		title: tr("menu.wallet.addressbook.add.title")
		visible: showAddDialog
		
		property string nameField: ""
		property string addressField: ""
		property string errorMessage: ""
		
		onClosed: {
			showAddDialog = false
			nameField = ""
			addressField = ""
			errorMessage = ""
		}
		
		ColumnLayout {
			anchors.fill: parent
			spacing: 15
			
			Text {
				text: tr("menu.wallet.addressbook.add.name")
				color: colors.primaryText
			}
			
			TextField {
				id: nameInput
				Layout.fillWidth: true
				text: addDialog.nameField
				onTextChanged: addDialog.nameField = text
				placeholderText: "Enter name"
				color: colors.primaryText
				background: Rectangle {
					color: colors.secondaryBackground
					border.color: colors.border
					border.width: 1
					radius: 4
				}
			}
			
			Text {
				text: tr("menu.wallet.addressbook.add.address")
				color: colors.primaryText
			}
			
			TextField {
				id: addressInput
				Layout.fillWidth: true
				text: addDialog.addressField
				onTextChanged: addDialog.addressField = text
				placeholderText: "Enter address"
				color: colors.primaryText
				background: Rectangle {
					color: colors.secondaryBackground
					border.color: colors.border
					border.width: 1
					radius: 4
				}
			}
			
			Text {
				text: addDialog.errorMessage
				color: "red"
				visible: addDialog.errorMessage !== ""
				wrapMode: Text.Wrap
			}
			
			RowLayout {
				Layout.fillWidth: true
				
				Button {
					text: tr("common.cancel")
					Layout.fillWidth: true
					onClicked: addDialog.close()
				}
				
				Button {
					text: tr("common.add")
					Layout.fillWidth: true
					enabled: addDialog.nameField.trim() !== "" && addDialog.addressField.trim() !== ""
					onClicked: {
						addDialog.errorMessage = ""
						addAddressBookItem(addDialog.nameField.trim(), addDialog.addressField.trim())
					}
				}
			}
		}
	}
	
	Dialog {
		id: editDialog
		modal: true
		anchors.centerIn: parent
		width: Math.min(400, parent.width - 40)
		height: 300
		title: tr("menu.wallet.addressbook.edit.title")
		visible: showEditDialog
		
		property string nameField: ""
		property string addressField: ""
		property string errorMessage: ""
		
		onClosed: {
			showEditDialog = false
			editingItemGuid = ""
			nameField = ""
			addressField = ""
			errorMessage = ""
		}
		
		ColumnLayout {
			anchors.fill: parent
			spacing: 15
			
			Text {
				text: tr("menu.wallet.addressbook.edit.name")
				color: colors.primaryText
			}
			
			TextField {
				Layout.fillWidth: true
				text: editDialog.nameField
				onTextChanged: editDialog.nameField = text
				placeholderText: "Enter name"
				color: colors.primaryText
				background: Rectangle {
					color: colors.secondaryBackground
					border.color: colors.border
					border.width: 1
					radius: 4
				}
			}
			
			Text {
				text: tr("menu.wallet.addressbook.edit.address")
				color: colors.primaryText
			}
			
			TextField {
				Layout.fillWidth: true
				text: editDialog.addressField
				onTextChanged: editDialog.addressField = text
				placeholderText: "Enter address"
				color: colors.primaryText
				background: Rectangle {
					color: colors.secondaryBackground
					border.color: colors.border
					border.width: 1
					radius: 4
				}
			}
			
			Text {
				text: editDialog.errorMessage
				color: "red"
				visible: editDialog.errorMessage !== ""
				wrapMode: Text.Wrap
			}
			
			RowLayout {
				Layout.fillWidth: true
				
				Button {
					text: tr("common.cancel")
					Layout.fillWidth: true
					onClicked: editDialog.close()
				}
				
				Button {
					text: tr("common.save")
					Layout.fillWidth: true
					enabled: editDialog.nameField.trim() !== "" && editDialog.addressField.trim() !== ""
					onClicked: {
						editDialog.errorMessage = ""
						editAddressBookItem(editingItemGuid, editDialog.nameField.trim(), editDialog.addressField.trim())
					}
				}
			}
		}
	}
	
	Dialog {
		id: deleteDialog
		modal: true
		anchors.centerIn: parent
		width: Math.min(350, parent.width - 40)
		height: 200
		title: tr("menu.wallet.addressbook.delete.title")
		visible: showDeleteDialog
		
		onClosed: {
			showDeleteDialog = false
			deleteItemGuid = ""
			deleteItemName = ""
		}
		
		ColumnLayout {
			anchors.fill: parent
			spacing: 20
			
			Text {
				text: tr("menu.wallet.addressbook.delete.confirm") + " \"" + deleteItemName + "\"?"
				color: colors.primaryText
				wrapMode: Text.Wrap
				Layout.fillWidth: true
			}
			
			RowLayout {
				Layout.fillWidth: true
				
				Button {
					text: tr("common.cancel")
					Layout.fillWidth: true
					onClicked: deleteDialog.close()
				}
				
				Button {
					text: tr("common.delete")
					Layout.fillWidth: true
					onClicked: {
						deleteAddressBookItem(deleteItemGuid)
					}
				}
			}
		}
	}
}
