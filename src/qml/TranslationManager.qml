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
		loadTranslations(currentLanguage, function(data) {
			console.log("Translations loaded successfully")
		}, function(error) {
			console.log("Failed to load translations:", error)
		})
	}
	
	Component.onCompleted: {
		console.log("TranslationManager singleton initializing...")
		loadTranslations(currentLanguage, function(data) {
			console.log("Initial translations loaded successfully")
		}, function(error) {
			console.log("Failed to load initial translations:", error)
		})
	}
	
	function loadTranslations(language, onSuccess, onError) {
		var xhr = new XMLHttpRequest()
		var url = Qt.resolvedUrl("translations/" + language + ".json")
		console.log("Loading translations from:", url)
		xhr.onreadystatechange = function() {
			console.log("XHR state changed, readyState:", xhr.readyState, "status:", xhr.status)
			if (xhr.readyState === XMLHttpRequest.DONE) {
				console.log("XHR finished - Status:", xhr.status, "Response length:", xhr.responseText.length)
				if (xhr.status >= 200 && xhr.status < 300) {
					try {
						var parsed = JSON.parse(xhr.responseText)
						console.log("JSON parsed successfully, keys:", Object.keys(parsed))
						translations = parsed
						console.log("Translations assigned, current keys:", Object.keys(translations))
						languageVersion++ // Trigger binding updates
						languageChanged()
						console.log("Language loaded:", language)
						if (onSuccess && typeof onSuccess === 'function') onSuccess(translations)
					} catch (e) {
						console.log("Error parsing translations:", e)
						if (onError && typeof onError === 'function') onError("Parse error: " + e.toString())
					}
				} else {
					var errorMsg = "HTTP " + xhr.status + ": " + xhr.statusText
					console.log("Error loading translations for", language, ":", errorMsg)
					// Call error callback if provided
					if (onError && typeof onError === 'function') onError(errorMsg)
				}
			}
		}
		xhr.open("GET", url, true)
		xhr.send()
	}
	
	function tr(key) {
		console.log("TranslationManager.tr called with:", key)
		console.log("Current translations object:", JSON.stringify(translations))
		console.log("Current translation keys:", Object.keys(translations))
		// This property access ensures binding updates when translations change
		var dummy = languageVersion
		var parts = key.split('.')
		if (parts.length < 2) {
			console.log("Invalid translation key format:", key)
			return key
		}
		// Navigate through the nested object structure
		var current = translations
		for (var i = 0; i < parts.length; i++) {
			if (!current || !current.hasOwnProperty(parts[i])) {
				console.log("Missing translation path at:", parts.slice(0, i + 1).join('.'))
				console.log("Available keys at this level:", current ? Object.keys(current) : "null")
				return key // Return the full key as fallback
			}
			current = current[parts[i]]
		}
		// If we found a string, use it
		if (typeof current === 'string') {
			var text = current
			// Simple argument substitution for %1, %2, etc.
			for (var i = 1; i < arguments.length; i++) {
				text = text.replace("%" + i, arguments[i])
			}
			return text
		}
		console.log("Translation key points to non-string value:", key, typeof current)
		return key // Return the full key as fallback
	}
	
	function setLanguage(language) {
		currentLanguage = language
	}
}
