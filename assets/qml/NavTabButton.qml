import QtQuick 2.12
import QtQuick.Controls 2.12
import FOXTracker.Theme 1.0

// Top navigation tab: small glyph + label, accent underline on the active tab.
TabButton {
    id: control

    property string iconGlyph: ""

    height: 48
    width: contentRow.implicitWidth + 36

    background: Rectangle {
        color: control.checked ? Theme.background : "transparent"

        // Accent underline for the current page.
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: control.checked ? parent.width : 0
            height: 2
            color: Theme.accent

            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        }
    }

    contentItem: Item {
        implicitWidth: contentRow.implicitWidth
        implicitHeight: contentRow.implicitHeight

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 7

            Text {
                text: control.iconGlyph
                color: control.checked ? Theme.accent : Theme.textDim
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: control.text
                color: control.checked ? Theme.text : Theme.textDim
                font.pixelSize: 13
                font.weight: control.checked ? Font.DemiBold : Font.Normal
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
