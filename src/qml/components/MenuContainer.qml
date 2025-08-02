import QtQuick 2.15
import QtQuick.Controls 2.15
import WalletModule 1.0

Item {
	id: root
	default property alias buttons: buttonsContainer.children
	
	// Automatically set windowHeight for all MenuButton children
	onButtonsChanged: {
		for (let i = 0; i < buttons.length; i++) {
			if (buttons[i].hasOwnProperty('windowHeight')) {
				buttons[i].windowHeight = Qt.binding(function() { return root.height; });
			}
			if (buttons[i].hasOwnProperty('flickableHeight')) {
				buttons[i].flickableHeight = Qt.binding(function() { return flickable.height; });
			}
		}
	}
	
	Flickable {
		id: flickable
		anchors.fill: parent
		anchors.leftMargin: parent.width * 0.05
		anchors.rightMargin: parent.width * 0.05
		contentWidth: width
		boundsBehavior: Flickable.StopAtBounds
		
		// Explicitní výpočet contentHeight
		property real calculatedContentHeight: {
			var totalHeight = 0;
			for (var i = 0; i < buttonsContainer.children.length; i++) {
				var child = buttonsContainer.children[i];
				if (child && child.height) {
					totalHeight += child.height;
				}
			}
			if (buttonsContainer.children.length > 1) {
				totalHeight += (buttonsContainer.children.length - 1) * buttonsContainer.spacing;
			}
			return totalHeight;
		}
		
		contentHeight: Math.max(calculatedContentHeight, height)
		
		// Scrollbar
		ScrollBar.vertical: ScrollBar {
			policy: ScrollBar.AsNeeded
		}
		
		Column {
			id: buttonsContainer
			width: flickable.width
			spacing: root.height * 0.03
		}
	}
}
