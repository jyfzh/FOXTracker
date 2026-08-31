import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FOXTracker.Theme 1.0

// Pure declarative UI form for the Setting page.
// Simple UI -> model wirings are kept here, matching the convention used by
// EkfPageForm.ui.qml. Any heavier logic (including C++ singleton access) lives
// in SettingPage.qml. The theme ComboBox is exposed via themeComboBox so the
// logic layer can bind it to the C++ ThemeManager singleton.
Page {
    id: form
    padding: 8

    // Explicit themed page background (the themed window palette in
    // MainWindow.qml already colors the style default; this is belt-and-braces).
    background: Rectangle {
        color: Theme.background
    }

    // Palette comes from the themed ApplicationWindow (MainWindow.qml);
    // items inherit it automatically.

    // Exposed so SettingPage.qml can wire the theme selection to ThemeManager.
    property alias themeComboBox: themeBox
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: 10

            GroupBox {
                title: "Appearance"
                Layout.fillWidth: true
                RowLayout {
                    spacing: 8
                    Label { text: "Theme" }
                    ComboBox {
                        id: themeBox
                        model: ["System", "Light", "Dark"]
                        // currentIndex + onActivated are wired from SettingPage.qml
                    }
                    Item { Layout.fillWidth: true }
                }
            }

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
                    SpinBox { from: 1; to: 65535; value: fox.port; editable: true; onValueModified: fox.port = value }
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
                    Slider {
                        from: 0; to: 1; stepSize: 0.01; value: fox.pitchOffsetFsaPnp; Layout.fillWidth: true; onMoved: fox.pitchOffsetFsaPnp = value
                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: (event) => {
                                var delta = event.angleDelta.y
                                if (delta === 0) return
                                var step = 0.01
                                var steps = Math.round(delta / 120)
                                var newVal = parent.value + steps * step
                                newVal = Math.max(parent.from, Math.min(parent.to, newVal))
                                if (newVal !== parent.value) {
                                    parent.value = newVal
                                    fox.pitchOffsetFsaPnp = newVal
                                }
                                event.accepted = true
                            }
                        }
                    }
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
