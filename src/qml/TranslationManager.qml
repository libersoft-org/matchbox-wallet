pragma Singleton
import QtQuick 2.15

QtObject {
	id: root
	
	property string currentLanguage: "en"
	property var translations: ({})
	property int languageVersion: 0  // This will trigger binding updates
	
	signal languageChanged()
	
	// Watch for currentLanguage changes
	onCurrentLanguageChanged: {
		loadTranslations(currentLanguage)
	}
	
	Component.onCompleted: {
		console.log("TranslationManager singleton initializing...")
		loadTranslations(currentLanguage)
	}
	
	function loadTranslations(language) {
		// Load from JSON files
		var xhr = new XMLHttpRequest()
		var url = Qt.resolvedUrl("translations/" + language + ".json")
		console.log("Loading translations from:", url)
		
				xhr.onreadystatechange = function() {
			if (xhr.readyState === XMLHttpRequest.DONE) {
				console.log("XHR finished with status:", xhr.status)
				if (xhr.status === 200) {
					try {
						translations = JSON.parse(xhr.responseText)
						languageVersion++  // Trigger binding updates
						languageChanged()
						console.log("Language loaded:", language)
					} catch (e) {
						console.log("Error parsing translations:", e)
					}
				} else {
					console.log("Error loading translations for", language, "status:", xhr.status)
				}
			}
		}		xhr.open("GET", url, true)
		xhr.send()
	}
	
	function tr(key) {
		console.log("TranslationManager.tr called with:", key)
		// This property access ensures binding updates when translations change
		var dummy = languageVersion
		
		var parts = key.split('.')
		if (parts.length !== 2) {
			console.log("Invalid translation key format:", key)
			return key
		}
		
		var section = parts[0]
		var subkey = parts[1]
		
		if (!translations[section] || !translations[section][subkey]) {
			console.log("Missing translation:", key)
			return subkey
		}
		
		var text = translations[section][subkey]
		
		// Simple argument substitution for %1, %2, etc.
		for (var i = 1; i < arguments.length; i++) {
			text = text.replace("%" + i, arguments[i])
		}
		
		return text
	}
	
	function setLanguage(language) {
		currentLanguage = language
	}
}
