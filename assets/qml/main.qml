import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import FOXTracker 1.0

ApplicationWindow {
    id: root
    visible: true
    width: 904
    height: 675
    minimumWidth: 640
    minimumHeight: 420
    title: "FOXTracker"
    color: "#1e1e1e"

    Component.onCompleted: fox.setWindow(root)

    onVisibilityChanged: (visibility === Window.Minimized) && fox.minimizeToTray()
    onClosing: fox.requestClose()

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
            MenuItem {
                text: "always on top"
                checkable: true
                checked: fox.alwaysOnTop
                onTriggered: fox.alwaysOnTop = !fox.alwaysOnTop
            }
            MenuItem { text: "toggle preview"; onTriggered: fox.togglePreview() }
        }
    }

    footer: ToolBar {
        background: Rectangle { color: "#2b2b2b" }
        RowLayout {
            anchors.fill: parent
            Label { text: "Face Tracking ..."; color: "lightgray" }
            Item { Layout.fillWidth: true }
            Label { text: "FPS: " + fox.fps.toFixed(1); color: "lightgray" }
            Label {
                text: "Time: " + fox.timeSec.toFixed(2)
                color: "lightgray"
                Layout.preferredWidth: 120
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: tabBar
            Layout.fillWidth: true
            TabButton { text: "Preview" }
            TabButton { text: "EKF" }
            TabButton { text: "Filter" }
            TabButton { text: "Setting" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // Preview page
            RowLayout {
                spacing: 12
                GroupBox {
                    title: "position"
                    Layout.preferredWidth: 240
                    Layout.alignment: Qt.AlignTop
                    GridLayout {
                        anchors.fill: parent
                        columns: 2
                        rowSpacing: 6
                        columnSpacing: 6
                        Label { text: "X"; horizontalAlignment: Text.AlignHCenter }
                        LcdDisplay { value: fox.x }
                        Label { text: "Y"; horizontalAlignment: Text.AlignHCenter }
                        LcdDisplay { value: fox.y }
                        Label { text: "Z"; horizontalAlignment: Text.AlignHCenter }
                        LcdDisplay { value: fox.z }
                    }
                }
                GroupBox {
                    title: "pose"
                    Layout.preferredWidth: 240
                    Layout.alignment: Qt.AlignTop
                    GridLayout {
                        anchors.fill: parent
                        columns: 2
                        rowSpacing: 6
                        columnSpacing: 6
                        Label { text: "Yaw"; horizontalAlignment: Text.AlignHCenter }
                        LcdDisplay { value: fox.yaw }
                        Label { text: "Pitch"; horizontalAlignment: Text.AlignHCenter }
                        LcdDisplay { value: fox.pitch }
                        Label { text: "Roll"; horizontalAlignment: Text.AlignHCenter }
                        LcdDisplay { value: fox.roll }
                    }
                }
                PreviewView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    controller: fox
                }
            }

            // EKF config page
            EkfPage {}
            // Filter config page
            FilterPage {}
            // Setting config page
            SettingPage {}
        }
    }
}
