import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	title: qsTr("Language Selection")
	
	signal languageSelected(string language)
	
	MenuButton {
		text: qsTr("English")
		onClicked: {
			root.languageSelected("en");
		}
	}
	
	MenuButton {
		text: qsTr("Czech")
		onClicked: {
			root.languageSelected("cz");
		}
	}
}
