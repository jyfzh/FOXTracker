import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import FOXTracker 1.0

Page {
    id: form
    padding: 8

    property real posX: 0
    property real posY: 0
    property real posZ: 0
    property real poseYaw: 0
    property real posePitch: 0
    property real poseRoll: 0
    property var previewController: null

    property alias logView: log_area
    property alias logFlick: log_flick
    property alias startButton: start_button
    property alias stopButton: stop_button
    property alias previewButton: preview_button
    property alias centerButton: center_button

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
                            horizontalAlignment: Text.AlignHCenter
                        }
                        LcdDisplay {
                            value: posX
                        }
                        Label {
                            text: "Y"
                            horizontalAlignment: Text.AlignHCenter
                        }
                        LcdDisplay {
                            value: posY
                        }
                        Label {
                            text: "Z"
                            horizontalAlignment: Text.AlignHCenter
                        }
                        LcdDisplay {
                            value: posZ
                        }
                    }
                }
                Item {
                    Layout.fillHeight: true
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
                            horizontalAlignment: Text.AlignHCenter
                        }
                        LcdDisplay {
                            value: poseYaw
                        }
                        Label {
                            text: "Pitch"
                            horizontalAlignment: Text.AlignHCenter
                        }
                        LcdDisplay {
                            value: posePitch
                        }
                        Label {
                            text: "Roll"
                            horizontalAlignment: Text.AlignHCenter
                        }
                        LcdDisplay {
                            value: poseRoll
                        }
                    }
                }
                Item {
                    Layout.fillHeight: true
                }
                GroupBox {
                    title: ""
                    Layout.preferredWidth: 240
                    Layout.alignment: Qt.AlignTop
                    GridLayout {
                        anchors.fill: parent
                        columns: 2
                        rowSpacing: 6
                        columnSpacing: 6
                        Button {
                            id: start_button
                            text: "Start"
                        }
                        Button  {
                            id: stop_button
                            text: "Stop"
                        }
                        Button  {
                            id: preview_button
                            text: "Preview"
                        }
                        Button  {
                            id: center_button
                            text: "Center"
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
                    id: log_flick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: log_area.implicitWidth
                    contentHeight: log_area.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

                    TextArea {
                        id: log_area
                        width: log_flick.width
                        height: Math.max(implicitHeight, log_flick.height)
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
