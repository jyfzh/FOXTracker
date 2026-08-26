import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import FOXTracker.Theme 1.0

Item {
    id: form
    implicitWidth: 904
    implicitHeight: 675

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: tabBar
            Layout.fillWidth: true
            height: 48
            spacing: 4

            background: Rectangle {
                color: Theme.panel

                // Hairline separating the nav bar from the page area.
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.border
                }
            }

            NavTabButton {
                iconGlyph: "\u25C9" // ◉ camera / preview
                text: qsTr("Preview")
            }
            NavTabButton {
                iconGlyph: "\u223F" // ∿ signal
                text: "EKF"
            }
            NavTabButton {
                iconGlyph: "\u2630" // ☰ filter lines
                text: qsTr("Filter")
            }
            NavTabButton {
                iconGlyph: "\u2699" // ⚙ gear
                text: qsTr("Settings")
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            PreviewPage {}
            EkfPage {}
            FilterPage {}
            SettingPage {}
        }
    }
}
