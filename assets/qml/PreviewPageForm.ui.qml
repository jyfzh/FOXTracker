import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import FOXTracker 1.0

Page {
    id: form
    padding: 8

    // Properties to receive data from the logic layer (PreviewPage.qml)
    // .ui.qml files cannot directly access context properties like 'fox'
    property real posX: 0
    property real posY: 0
    property real posZ: 0
    property real poseYaw: 0
    property real posePitch: 0
    property real poseRoll: 0
    property var previewController: null

    // Log display — expose the controls to the logic layer (PreviewPage.qml),
    // since .ui.qml files cannot access context properties or define JS logic.
    property alias logView: logArea
    property alias logFlick: logFlick

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        RowLayout {
            spacing: 12
            PreviewView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                controller: previewController
            }
            ColumnLayout {
                GroupBox {
                    title: "position"
                    Layout.preferredWidth: 240
                    Layout.alignment: Qt.AlignTop
                    GridLayout {
                        anchors.fill: parent
                        columns: 2
                        rowSpacing: 6
                        columnSpacing: 6
                        Label {
                            text: "X"
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                        LcdDisplay {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            value: posX
                        }
                        Label {
                            text: "Y"
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                        LcdDisplay {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            value: posY
                        }
                        Label {
                            text: "Z"
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                        LcdDisplay {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            value: posZ
                        }
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
                        Label {
                            text: "Yaw"
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                        LcdDisplay {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            value: poseYaw
                        }
                        Label {
                            text: "Pitch"
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                        LcdDisplay {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            value: posePitch
                        }
                        Label {
                            text: "Roll"
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                        LcdDisplay {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            value: poseRoll
                        }
                    }
                }
            }
        }

        GroupBox {
            title: "log"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 140

            ColumnLayout {
                anchors.fill: parent
                spacing: 6

                Flickable {
                    id: logFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: logArea.implicitWidth
                    contentHeight: logArea.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

                    TextArea {
                        id: logArea
                        width: logFlick.width
                        height: Math.max(implicitHeight, logFlick.height)
                        readOnly: true
                        textFormat: Text.RichText
                        wrapMode: Text.Wrap
                        placeholderText: "log start..."
                        selectByMouse: true
                        font.family: "Consolas, Menlo, Monaco, monospace"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
