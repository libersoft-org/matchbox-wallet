import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0

Item {
	id: root
	property string title: ""
	default property alias buttons: menuContainer.buttons
	signal backRequested

	MenuContainer {
		id: menuContainer
		anchors.fill: parent
	}
}
