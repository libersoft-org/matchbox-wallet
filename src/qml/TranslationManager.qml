pragma Singleton
import QtQuick 2.15

QtObject {
	id: root
	
	property string currentLanguage: "en"
	property var translations: ({})
	
	signal languageChanged()
	
	Component.onCompleted: {
		loadTranslations(currentLanguage)
	}
	
	function loadTranslations(language) {
		var xhr = new XMLHttpRequest()
		xhr.open("GET", Qt.resolvedUrl("translations/" + language + ".json"), false)
		xhr.send()
		
		if (xhr.status === 200) {
			try {
				translations = JSON.parse(xhr.responseText)
				currentLanguage = language
				languageChanged()
			} catch (e) {
				console.log("Error parsing translations:", e)
			}
		} else {
			console.log("Error loading translations for", language)
		}
	}
	
	function setLanguage(language) {
		loadTranslations(language)
	}
	
	function tr(section, key, ...args) {
		if (!translations[section] || !translations[section][key]) {
			console.log("Missing translation:", section + "." + key)
			return key
		}
		
		var text = translations[section][key]
		
		// Simple argument substitution for %1, %2, etc.
		for (var i = 0; i < args.length; i++) {
			text = text.replace("%" + (i + 1), args[i])
		}
		
		return text
	}
	
	function getLanguageDisplayName(language) {
		switch (language) {
			case "en": return tr("settingsGeneralLanguage", "english")
			case "cz": return tr("settingsGeneralLanguage", "czech")
			default: return language
		}
	}
}
