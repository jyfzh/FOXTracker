import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import FOXTracker 1.0
import FOXTracker.Theme 1.0

// Window + lifecycle logic for the main window.
// The pure UI declaration (contents) is in MainWindowForm.ui.qml.
ApplicationWindow {
    id: root
    visible: true
    width: 904
    height: 775
    minimumWidth: 640
    minimumHeight: 420
    title: "FOXTracker"
    color: Theme.background

    footer: ToolBar {
        height: 30

        background: Rectangle {
            color: Theme.panel
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: Theme.border
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 8
            Item { Layout.preferredWidth: 6 }

            // Status light + tracking state.
            Rectangle {
                width: 8; height: 8; radius: 4
                color: fox.running ? Theme.success : Theme.textDim
            }
            Label {
                text: fox.running ? "TRACKING ON" : "STANDBY"
                color: fox.running ? Theme.success : Theme.textDim
                font.family: Theme.monoFont
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1
            }

            Item { Layout.fillWidth: true }

            Label {
                text: "FPS " + fox.fps.toFixed(1)
                color: Theme.textDim
                font.family: Theme.monoFont
                font.pixelSize: 11
            }
            Label {
                text: "TIME " + fox.timeSec.toFixed(2) + " s"
                color: Theme.textDim
                font.family: Theme.monoFont
                font.pixelSize: 11
            }
            Item { Layout.preferredWidth: 10 }
        }
    }

    MainWindowForm { anchors.fill: parent }

    Component.onCompleted: fox.setWindow(root)
    onVisibilityChanged: (visibility === Window.Minimized) && fox.minimizeToTray()
    onClosing: fox.requestClose()
}
