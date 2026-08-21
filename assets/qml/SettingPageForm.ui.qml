import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

// Pure declarative UI form for the Setting page.
// Simple UI -> model wirings are kept here, matching the convention used by
// EkfPageForm.ui.qml. Any heavier logic would live in SettingPage.qml.
Page {
    id: form
    padding: 8
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: 10

            GroupBox {
                title: "Output"
                Layout.fillWidth: true
                GridLayout {
                    columns: 2
                    rowSpacing: 4
                    columnSpacing: 16
                    CheckBox { text: "FreeTrack / TrackIR"; checked: fox.useFt; onToggled: fox.useFt = checked }
                    CheckBox { text: "Send UDP"; checked: fox.sendPoseUdp; onToggled: fox.sendPoseUdp = checked }
                    Label { text: "UDP Host" }
                    TextField { text: fox.udpHost; onEditingFinished: fox.udpHost = text }
                    Label { text: "UDP Port" }
                    SpinBox { from: 1; to: 65535; value: fox.port; onValueModified: fox.port = value }
                }
            }

            GroupBox {
                title: "Camera"
                Layout.fillWidth: true
                GridLayout {
                    columns: 2
                    rowSpacing: 4
                    columnSpacing: 16
                    Label { text: "Camera ID" }
                    SpinBox { from: 0; to: 8; value: fox.cameraId; onValueModified: fox.cameraId = value }
                    Label { text: "Detect Duration" }
                    SpinBox { from: 1; to: 120; value: fox.detectDuration; onValueModified: fox.detectDuration = value }
                    Label { text: "FPS" }
                    SpinBox { from: 1; to: 240; value: fox.detectFps; onValueModified: fox.detectFps = value }
                    Label { text: "Gain" }
                    Slider { from: 0; to: 1; stepSize: 0.01; value: fox.cameraGain; Layout.fillWidth: true; onMoved: fox.cameraGain = value }
                    Label { text: "Exposure" }
                    Slider { from: 0; to: 1; stepSize: 0.01; value: fox.cameraExpo; Layout.fillWidth: true; onMoved: fox.cameraExpo = value }
                    CheckBox { text: "Auto Exposure"; checked: fox.enableAutoExpo; onToggled: fox.enableAutoExpo = checked }
                }
            }

            GroupBox {
                title: "Landmark / Model"
                Layout.fillWidth: true
                GridLayout {
                    columns: 2
                    rowSpacing: 4
                    columnSpacing: 16
                    Label { text: "Method" }
                    ComboBox {
                        id: lm
                        model: ["dlib (-1)", "network 0", "network 1", "network 2", "network 3"]
                        currentIndex: fox.landmarkDetectMethod + 1
                        onActivated: fox.landmarkDetectMethod = currentIndex - 1
                    }
                    Label { text: "PnP/FSA Offset" }
                    Slider { from: 0; to: 1; stepSize: 0.01; value: fox.pitchOffsetFsaPnp; Layout.fillWidth: true; onMoved: fox.pitchOffsetFsaPnp = value }
                }
            }

            GroupBox {
                title: "Joystick Hotkeys"
                Layout.fillWidth: true
                ColumnLayout {
                    RowLayout {
                        Label { text: "Re-center:" }
                        Button { text: "Bind"; onClicked: fox.bindHotkey(0) }
                        Label { text: fox.hotkeyJoystick1 + " / Button " + fox.hotkeyButton1 }
                        Button { text: "Unbind"; onClicked: fox.unbindHotkey(0) }
                    }
                    RowLayout {
                        Label { text: "Pause:" }
                        Button { text: "Bind"; onClicked: fox.bindHotkey(1) }
                        Label { text: fox.hotkeyJoystick2 + " / Button " + fox.hotkeyButton2 }
                        Button { text: "Unbind"; onClicked: fox.unbindHotkey(1) }
                    }
                }
            }

            Button {
                text: "Save Config"
                Layout.alignment: Qt.AlignRight
                onClicked: fox.saveConfig()
            }
        }
    }
}
