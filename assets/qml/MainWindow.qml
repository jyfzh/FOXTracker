import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import FOXTracker 1.0

// Window + lifecycle logic for the main window.
// The pure UI declaration (contents) is in MainWindowForm.ui.qml.
ApplicationWindow {
    id: root
    visible: true
    width: 904
    height: 675
    minimumWidth: 640
    minimumHeight: 420
    title: "FOXTracker"
    color: "white"

    menuBar: MenuBar {
        Menu {
            title: "option"
            MenuItem { text: "start"; onTriggered: fox.start() }
            MenuItem { text: "stop"; onTriggered: fox.stop() }
            MenuItem { text: "pause"; onTriggered: fox.pause() }
            MenuSeparator {}
            MenuItem { text: "center"; onTriggered: fox.center() }
        }
        Menu {
            title: "config"
            MenuItem { text: "always on top"; onTriggered: fox.alwaysOnTop = !fox.alwaysOnTop }
            MenuItem { text: "toggle preview"; onTriggered: fox.togglePreview() }
        }
    }

    footer: ToolBar {
        background: Rectangle { color: "#2b2b2b" }
        RowLayout {
            anchors.fill: parent
            Label { text: "Face Tracking ..."; color: "lightgray" }
            Item { Layout.fillWidth: true }
            Label {
                text: "FPS: " + fox.fps.toFixed(1)
                color: "lightgray"
            }
            Label {
                text: "Time: " + fox.timeSec.toFixed(2)
                color: "lightgray"
                Layout.preferredWidth: 120
            }
        }
    }

    MainWindowForm { anchors.fill: parent }

    Component.onCompleted: fox.setWindow(root)
    onVisibilityChanged: (visibility === Window.Minimized) && fox.minimizeToTray()
    onClosing: fox.requestClose()
}
