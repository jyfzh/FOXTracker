import QtQuick 2.12
import QtQuick.Controls 2.12

// LCD-style numeric readout used for the pose / position values.
Rectangle {
    property real value: 0

    color: "#202020"
    border.color: "#555555"
    border.width: 2
    radius: 10
    implicitWidth: 120
    implicitHeight: 44

    Text {
        anchors.centerIn: parent
        text: parent.value.toFixed(2)
        color: "#00ff00"
        font.family: "Source Code Variable"
        font.pixelSize: 18
    }
}
