import QtQuick 2.15
import QtQuick.Controls 2.15

Switch {
    id:control
    property color backgroundColor: colors.primaryBackground

    indicator: Rectangle{
        implicitHeight: 32
        implicitWidth: 56
        x:control.leftPadding
        y:parent.height /2 - height/2
        radius: width/2
        color: control.checked ? colors.success : colors.warning
        border.width: control.checked ? 2 : 1
        border.color: control.checked ? colors.warning : colors.success

        Rectangle{
            x:control.checked ? (parent.width-width) - 2: 2
            width: 28
            height: 28
            radius: height/2
            color: control.checked ? colors.primaryForeground : colors.disabledForeground
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    contentItem: Label {
        color: colors.primaryForeground
        text: control.text
        font.pixelSize: 16
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing
    }
}
