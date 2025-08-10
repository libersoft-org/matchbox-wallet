import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../../components"

BaseMenu {
    id: root
    title: tr("menu.settings.system.time.timezone")

    signal timezoneSelected(string tz)

    // Load time zones from system
    property var timezones: []

    Component.onCompleted: {
        try {
            if (SystemManager && SystemManager.listTimeZones)
                timezones = SystemManager.listTimeZones();
        } catch (e) {
            console.log("Failed to load time zones:", e)
        }
        if (!timezones || timezones.length === 0) {
            timezones = ["UTC"]
        }
    }

    Repeater {
        model: root.timezones
        delegate: MenuButton {
            text: modelData
            onClicked: root.timezoneSelected(modelData)
        }
    }
}
