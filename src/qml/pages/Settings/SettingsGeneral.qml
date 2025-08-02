import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	title: qsTr("General settings")
	
	signal currencySelectionRequested
	signal languageSelectionRequested
	
	property string selectedCurrency: "USD"
	property string selectedLanguage: "en"
	
	MenuButton {
		text: qsTr("Fiat Currency: %1").arg(root.selectedCurrency)
		onClicked: {
			root.currencySelectionRequested();
		}
	}
	
	MenuButton {
		text: qsTr("Language: %1").arg(TranslationManager.getLanguageDisplayName(root.selectedLanguage))
		onClicked: {
			root.languageSelectionRequested();
		}
	}
}
