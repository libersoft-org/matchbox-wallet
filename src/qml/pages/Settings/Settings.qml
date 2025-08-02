import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
 id: root
 color: "#f0f0f0"

 signal backRequested
 signal systemSettingsRequested

 ColumnLayout {
  anchors.fill: parent
  anchors.margins: 20
  spacing: 20

  // Header with back button and title
  RowLayout {
   Layout.fillWidth: true

   Button {
	id: backButton
	Layout.preferredWidth: 80
	Layout.preferredHeight: 40
	text: qsTr("← Back")

	background: Rectangle {
	 color: backButton.pressed ? "#e0e0e0" : (backButton.hovered ? "#f0f0f0" : "#f8f9fa")
	 radius: 6
	 border.color: "#6c757d"
	 border.width: 1
	}

	contentItem: Text {
	 text: backButton.text
	 font.pointSize: 10
	 color: "#333333"
	 horizontalAlignment: Text.AlignHCenter
	 verticalAlignment: Text.AlignVCenter
	}

	onClicked: {
	 root.backRequested();
	}
   }

   Text {
	text: qsTr("Settings")
	font.pointSize: 24
	font.bold: true
	color: "#333333"
	Layout.alignment: Qt.AlignHCenter
	Layout.fillWidth: true
	horizontalAlignment: Text.AlignHCenter
   }

   // Spacer to center the title
   Item {
	Layout.preferredWidth: 80
   }
  }

  // Settings menu container
  Rectangle {
   Layout.fillWidth: true
   Layout.fillHeight: true
   color: "white"
   border.color: "#cccccc"
   border.width: 1
   radius: 8

   ColumnLayout {
	anchors.fill: parent
	anchors.margins: 30
	spacing: 15

	// General settings button
	Button {
	 id: generalButton
	 Layout.fillWidth: true
	 Layout.preferredHeight: 60
	 text: qsTr("General")
	 enabled: false // Not implemented yet

	 background: Rectangle {
	  color: generalButton.enabled ? (generalButton.pressed ? "#e0e0e0" : (generalButton.hovered ? "#f0f0f0" : "#ffffff")) : "#f8f9fa"
	  radius: 6
	  border.color: generalButton.enabled ? "#6c757d" : "#dee2e6"
	  border.width: 1
	 }

	 contentItem: Text {
	  text: generalButton.text
	  font.pointSize: 14
	  color: generalButton.enabled ? "#333333" : "#6c757d"
	  horizontalAlignment: Text.AlignLeft
	  verticalAlignment: Text.AlignVCenter
	  leftPadding: 20
	 }

	 onClicked: {
	  console.log("General settings clicked - not implemented yet");
	 }
	}

	// Networks settings button
	Button {
	 id: networksButton
	 Layout.fillWidth: true
	 Layout.preferredHeight: 60
	 text: qsTr("Networks")
	 enabled: false // Not implemented yet

	 background: Rectangle {
	  color: networksButton.enabled ? (networksButton.pressed ? "#e0e0e0" : (networksButton.hovered ? "#f0f0f0" : "#ffffff")) : "#f8f9fa"
	  radius: 6
	  border.color: networksButton.enabled ? "#6c757d" : "#dee2e6"
	  border.width: 1
	 }

	 contentItem: Text {
	  text: networksButton.text
	  font.pointSize: 14
	  color: networksButton.enabled ? "#333333" : "#6c757d"
	  horizontalAlignment: Text.AlignLeft
	  verticalAlignment: Text.AlignVCenter
	  leftPadding: 20
	 }

	 onClicked: {
	  console.log("Networks settings clicked - not implemented yet");
	 }
	}

	// Wallets settings button
	Button {
	 id: walletsButton
	 Layout.fillWidth: true
	 Layout.preferredHeight: 60
	 text: qsTr("Wallets")
	 enabled: false // Not implemented yet

	 background: Rectangle {
	  color: walletsButton.enabled ? (walletsButton.pressed ? "#e0e0e0" : (walletsButton.hovered ? "#f0f0f0" : "#ffffff")) : "#f8f9fa"
	  radius: 6
	  border.color: walletsButton.enabled ? "#6c757d" : "#dee2e6"
	  border.width: 1
	 }

	 contentItem: Text {
	  text: walletsButton.text
	  font.pointSize: 14
	  color: walletsButton.enabled ? "#333333" : "#6c757d"
	  horizontalAlignment: Text.AlignLeft
	  verticalAlignment: Text.AlignVCenter
	  leftPadding: 20
	 }

	 onClicked: {
	  console.log("Wallets settings clicked - not implemented yet");
	 }
	}

	// System settings button
	Button {
	 id: systemButton
	 Layout.fillWidth: true
	 Layout.preferredHeight: 60
	 text: qsTr("System")

	 background: Rectangle {
	  color: systemButton.pressed ? "#0066cc" : (systemButton.hovered ? "#3399ff" : "#ffffff")
	  radius: 6
	  border.color: "#007bff"
	  border.width: 1
	 }

	 contentItem: Text {
	  text: systemButton.text
	  font.pointSize: 14
	  color: systemButton.pressed || systemButton.hovered ? "white" : "#007bff"
	  horizontalAlignment: Text.AlignLeft
	  verticalAlignment: Text.AlignVCenter
	  leftPadding: 20
	 }

	 onClicked: {
	  root.systemSettingsRequested();
	 }
	}

	// Spacer to push content to top
	Item {
	 Layout.fillHeight: true
	}
   }
  }
 }
}
