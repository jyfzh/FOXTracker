import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
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

    palette.window: Theme.background
    palette.windowText: Theme.text
    palette.base: Theme.input
    palette.alternateBase: Theme.panel
    palette.text: Theme.text
    palette.button: Theme.panel
    palette.buttonText: Theme.text
    palette.highlight: Theme.accent
    palette.highlightedText: Theme.textOnAccent
    palette.toolTipBase: Theme.panel
    palette.toolTipText: Theme.text
    palette.link: Theme.accent

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
            Item {
                Layout.preferredWidth: 6
            }

            // Status light + tracking state.
            Rectangle {
                width: 8
                height: 8
                radius: 4
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

            Item {
                Layout.fillWidth: true
            }

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
            Item {
                Layout.preferredWidth: 10
            }
        }
    }

    MainWindowForm {
        anchors.fill: parent
    }

    Component.onCompleted: fox.setWindow(root)
    onVisibilityChanged: (visibility === Window.Minimized) && fox.minimizeToTray()
    onClosing: fox.requestClose()
}
