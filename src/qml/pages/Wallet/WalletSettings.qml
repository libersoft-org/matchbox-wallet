import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
	id: root
	title: tr("menu.wallet.settings.title")

	signal generalSettingsRequested

	MenuButton {
		text: tr("menu.wallet.settings.general.button")
		onClicked: root.generalSettingsRequested()
	}
}
