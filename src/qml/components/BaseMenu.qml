import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0

Item {
	id: root
	property string title: ""
	property bool showBackButton: true
	property bool showPowerButton: true
	default property alias buttons: menuContainer.buttons
	signal backRequested
	signal powerOffRequested

	// Navigation bar - fixed at top
	NavigationBar {
		id: navigationBar
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		height: root.height * 0.1
		title: root.title
		showBackButton: root.showBackButton
		showPowerButton: root.showPowerButton
		onBackRequested: root.backRequested()
		onPowerOffRequested: root.powerOffRequested()
	}
	
	// Menu container - below navigation bar
	MenuContainer {
		id: menuContainer
		anchors.top: navigationBar.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.leftMargin: root.width * 0.05
		anchors.rightMargin: root.width * 0.05
		anchors.topMargin: root.height * 0.03
	}
}
