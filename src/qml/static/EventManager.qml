import QtQuick 2.15
import "../utils/NodeUtils.js" as Node

QtObject {
	id: eventManager
	
	signal eventReceived(string eventType, var data)
	
	property Timer eventTimer: Timer {
		interval: 3500
		running: true
		repeat: true
		onTriggered: pollEvents()
	}
	
	function pollEvents() {
		Node.msg("popEvents", {}, function(response) {
			if (response && response.length > 0) {
				for (var i = 0; i < response.length; i++) {
					var event = response[i]
					eventReceived(event.type, event.value)
				}
			}
		})
	}
}