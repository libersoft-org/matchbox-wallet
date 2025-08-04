import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.settings.general.system.language.title")
	
	signal languageSelected(string languageCode)
	
	MenuButton {
		id: englishButton
		text: "English"
		onClicked: {
			root.languageSelected("en");
		}
	}
	
	MenuButton {
		id: czechButton
		text: "Čeština"
		onClicked: {
			root.languageSelected("cz");
		}
	}
}
