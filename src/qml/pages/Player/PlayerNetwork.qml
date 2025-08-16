import QtQuick 2.15
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.player.network")

	Column {
		width: parent.width
		spacing: window.width * 0.05

		Input {
			id: urlInput
			width: parent.width
			inputPlaceholder: tr("menu.player.url")
			inputType: "text"
		}

		MenuButton {
			text: tr("menu.player.open")
			onClicked: {
				if (urlInput.text.length > 0) {
					var videoPage = playerVideoPageComponent.createObject(null, {
						"sourceUrl": urlInput.text
					});
					window.stackView.push(videoPage);
				}
			}
		}
	}
}
