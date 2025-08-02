import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0

ScrollableContainer {
	id: root
	property string title: ""
	default property alias buttons: buttonsContainer.children
	signal backRequested
	
	// Automatically set windowHeight and flickableHeight for all MenuButton children  
	onButtonsChanged: {
		for (let i = 0; i < buttons.length; i++) {
			if (buttons[i].hasOwnProperty('windowHeight')) {
				buttons[i].windowHeight = Qt.binding(function() { return root.height; });
			}
			if (buttons[i].hasOwnProperty('flickableHeight')) {
				buttons[i].flickableHeight = Qt.binding(function() { return root.height; });
			}
		}
	}

	Column {
		id: buttonsContainer
		width: parent.width
		spacing: root.height * 0.03
	}
}
