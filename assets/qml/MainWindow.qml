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
    height: 775
    minimumWidth: 640
    minimumHeight: 420
    title: "FOXTracker"
    color: "white"

    footer: ToolBar {
        background: Rectangle { color: "#cfd1d1" }
        RowLayout {
            anchors.fill: parent
            Label { text: "Face Tracking ..." }
            Item { Layout.fillWidth: true }
            Label {
                text: "FPS: " + fox.fps.toFixed(1)
            }
            Label {
                text: "Time: " + fox.timeSec.toFixed(2)
                Layout.preferredWidth: 120
            }
        }
    }

    MainWindowForm { anchors.fill: parent }

    Component.onCompleted: fox.setWindow(root)
    onVisibilityChanged: (visibility === Window.Minimized) && fox.minimizeToTray()
    onClosing: fox.requestClose()
}
