import QtQuick 6.4
import "../../components"

BaseMenu {
	id: root
	property string title: tr("ai.title")
	property bool hasError: false
	property string errorMessage: ""

	function startConversation() {
		console.log('TODO - start conversa');
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
