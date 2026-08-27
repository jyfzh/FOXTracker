import QtQuick
import FOXTracker.Theme 1.0

// Compact LCD-style numeric readout used for the pose / position rows.
// Dark inset value box, right-aligned monospaced digits, optional unit (°).
Rectangle {
    id: root

    property real value: 0
    property string unit: ""

    color: Theme.input
    border.color: Theme.border
    border.width: 1
    radius: 4
    implicitWidth: 96
    implicitHeight: 26

    Text {
        anchors.fill: parent
        anchors.rightMargin: 10
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        text: root.value.toFixed(2) + root.unit
        color: Theme.text
        font.family: Theme.monoFont
        font.pixelSize: 13
    }
}
