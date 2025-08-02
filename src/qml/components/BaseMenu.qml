import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    color: "#f0f0f0"
    
    // Properties for customization
    property string title: ""
    default property alias buttons: buttonsContainer.children
    
    // Automatically set windowHeight for all MenuButton children
    onButtonsChanged: {
        for (var i = 0; i < buttons.length; i++) {
            if (buttons[i].hasOwnProperty('windowHeight')) {
                buttons[i].windowHeight = Qt.binding(function() { return root.height; });
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(20, root.width * 0.05)
        spacing: Math.max(20, root.height * 0.03)

        // Page title
        Text {
            text: root.title
            font.pointSize: Math.max(18, Math.min(36, root.width * 0.04))
            font.bold: true
            color: "#333333"
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Math.max(20, root.height * 0.05)
        }

        // Menu buttons container
        ColumnLayout {
            id: buttonsContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 15
            Layout.rightMargin: 15
            spacing: Math.max(15, root.height * 0.05)
        }
    }
}
