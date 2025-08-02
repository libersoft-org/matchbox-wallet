import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

BaseMenu {
	id: root
	anchors.fill: parent
	title: tr("settings.general.language.title")
	
	MenuButton {
		id: englishButton
		text: "English"
		onClicked: {
			parent.parent.languageSelected("en");
		}
	}
	
	MenuButton {
		id: czechButton
		text: "Czech"
		onClicked: {
			parent.parent.languageSelected("cz");
		}
	}
}
