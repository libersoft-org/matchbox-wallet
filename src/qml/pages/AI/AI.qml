import "../../components"

BaseMenu {
	anchors.fill: parent

	function startConversation() {
		console.log('TODO');
	}

	MenuButton {
		text: tr('ai.settings.button')
		onClicked: window.goPage('AI/AISettings.qml')
	}

	MenuButton {
		text: tr('ai.start')
		onClicked: startConversation()
	}

	Alert {
		visible: hasError
		type: 'error'
		message: errorMessage
	}
}
