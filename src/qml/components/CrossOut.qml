import QtQuick 2.15

Item {
    id: root
    
    // Cross lines for indicating disconnected/unavailable state
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: Math.max(2, parent.height * 0.15)
        color: "red"
        rotation: 45
        opacity: 0.9
    }
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: Math.max(2, parent.height * 0.15) 
        color: "red"
        rotation: -45
        opacity: 0.9
    }
}
