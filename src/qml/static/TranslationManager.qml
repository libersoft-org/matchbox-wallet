import QtQuick 6.8

QtObject {
	id: root

	property string currentLanguage: ""
	property var translations: ({})
	property int languageVersion: 0  // This will trigger binding updates

	signal languageChanged

	// Watch for currentLanguage changes
	onCurrentLanguageChanged: {
		console.log("TranslationManager: currentLanguage changed to:", currentLanguage);
		loadTranslations(currentLanguage, function (data) {
			console.log("Translations loaded successfully");
		}, function (error) {
			console.log("Failed to load translations:", error);
		});
	}

	/*
	Component.onCompleted: {
	 console.log("TranslationManager initializing...");
 	console.log("TranslationManager ready, waiting for language to be set");
	}
 */

	function loadTranslations(language, onSuccess, onError) {
		var xhr = new XMLHttpRequest();
		var url = "qrc:/WalletModule/src/qml/lang/" + language + ".json";
		//console.log("Loading translations from:", url);
		xhr.onreadystatechange = function () {
			//console.log("XHR state changed, readyState:", xhr.readyState, "status:", xhr.status);
			if (xhr.readyState === XMLHttpRequest.DONE) {
				//console.log("XHR finished - Status:", xhr.status, "Response length:", xhr.responseText.length);
				if (xhr.status >= 200 && xhr.status < 300 || xhr.status === 0) {
					// status 0 for local files
					try {
						var parsed = JSON.parse(xhr.responseText);
						//console.log("JSON parsed successfully, keys:", Object.keys(parsed));
						translations = parsed;
						console.log("Translations assigned, current keys:", Object.keys(translations));
						languageVersion++; // Trigger binding updates
						languageChanged();
						//console.log("Language loaded:", language);
						if (onSuccess && typeof onSuccess === 'function')
							onSuccess(translations);
					} catch (e) {
						console.error("Error parsing translations:", e);
						if (onError && typeof onError === 'function')
							onError("Parse error: " + e.toString());
					}
				} else {
					var errorMsg = "HTTP " + xhr.status + ": " + xhr.statusText;
					console.error("Error loading translations for", language, ":", errorMsg);
					// Call error callback if provided
					if (onError && typeof onError === 'function')
						onError(errorMsg);
				}
			}
		};
		xhr.open("GET", url, true);
		xhr.send();
	}

	function tr(key) {
		// This property access ensures binding updates when translations change
		var dummy = languageVersion;

		// Return "loading..." if translations is empty
		if (Object.keys(translations).length === 0) {
			return "loading...";
		}

		var parts = key.split('.');
		if (parts.length < 2) {
			console.log("Invalid translation key format:", key);
			return key;
		}
		// Navigate through the nested object structure
		var current = translations;
		for (var i = 0; i < parts.length; i++) {
			if (!current || !current.hasOwnProperty(parts[i])) {
				console.log("Missing translation path at:", parts.slice(0, i + 1).join('.'));
				console.log("Available keys at this level:", current ? Object.keys(current) : "null");
				return key; // Return the full key as fallback
			}
			current = current[parts[i]];
		}
		// If we found a string, use it
		if (typeof current === 'string') {
			var text = current;
			// Simple argument substitution for %1, %2, etc.
			for (var i = 1; i < arguments.length; i++) {
				text = text.replace("%" + i, arguments[i]);
			}
			return text;
		}
		console.log("Translation key points to non-string value:", key, typeof current);
		return key; // Return the full key as fallback
	}

	function setLanguage(language) {
		console.log("TranslationManager: setLanguage called with:", language);
		console.log("TranslationManager: current language before change:", currentLanguage);
		currentLanguage = language;
		console.log("TranslationManager: current language after change:", currentLanguage);
		// Force load translations even if language hasn't changed
		loadTranslations(language, function (data) {
			console.log("Translations loaded successfully in setLanguage");
		}, function (error) {
			console.log("Failed to load translations in setLanguage:", error);
		});
	}
}
