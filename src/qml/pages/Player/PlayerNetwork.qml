import QtQuick 2.15
import "../../components"

BaseMenu {
	id: root
	title: tr("player.network")

	Column {
		width: parent.width
		spacing: window.width * 0.05

		Input {
			id: urlInput
			width: parent.width
			inputPlaceholder: tr("player.url")
			inputType: "text"
		}

		MenuButton {
			text: tr("player.open")
			onClicked: {
				if (urlInput.text.length > 0) {
					window.goPage('Player/PlayerVideo.qml', null, {
						"sourceUrl": urlInput.text
					});
				}
			}
		}
	}
}
