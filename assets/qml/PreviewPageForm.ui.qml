import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import FOXTracker 1.0
import FOXTracker.Theme 1.0

Page {
    id: form
    padding: 10

    // Themed page background: overrides the style default (palette.window),
    // which does not follow runtime palette changes reliably in Qt 5.
    background: Rectangle {
        color: Theme.background
    }

    // Explicit themed palette for all descendant controls: Qt 5 does not
    // propagate runtime application-palette changes to already-created items
    // (verified by experiment), so stock Fusion-styled children would keep
    // their startup colors — e.g. black labels on a dark background. Binding
    // the palette here propagates reactively down the control tree instead.
    // Keep in sync with ThemeManager::makePalette().
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

    property real posX: 0
    property real posY: 0
    property real posZ: 0
    property real poseYaw: 0
    property real posePitch: 0
    property real poseRoll: 0

    // Live status for the viewport HUD (bound from PreviewPage.qml).
    property bool running: false
    property real fps: 0
    property int previewWidth: 0
    property int previewHeight: 0

    property var previewController: null
    property bool logExpanded: false

    property alias logView: log_area
    property alias logFlick: log_flick
    property alias startButton: start_button
    property alias stopButton: stop_button
    property alias previewButton: preview_button
    property alias centerButton: center_button
    property alias clearLogButton: clear_log_button

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            spacing: 14
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ---- Camera preview with HUD overlay -----------------------
            Item {
                id: viewport
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                PreviewView {
                    anchors.fill: parent
                    controller: previewController
                }

                // Top-left: tracking state.
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 8
                    radius: 3
                    color: Theme.overlay
                    implicitHeight: hudState.implicitHeight + 10
                    implicitWidth: hudState.implicitWidth + 16

                    Row {
                        id: hudState
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            width: 7; height: 7; radius: 3.5
                            color: form.running ? Theme.hudSuccess : Theme.hudDim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: form.running ? "TRACKING" : "STANDBY"
                            color: form.running ? Theme.hudSuccess : Theme.hudDim
                            font.family: Theme.monoFont
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Top-right: FPS.
                Rectangle {
                    visible: form.fps > 0
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 8
                    radius: 3
                    color: Theme.overlay
                    implicitHeight: hudFps.implicitHeight + 10
                    implicitWidth: hudFps.implicitWidth + 16

                    Text {
                        id: hudFps
                        anchors.centerIn: parent
                        text: form.fps.toFixed(1) + " FPS"
                        color: Theme.hudText
                        font.family: Theme.monoFont
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1
                    }
                }

                // Bottom-right: camera resolution.
                Rectangle {
                    visible: form.previewWidth > 0
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 8
                    radius: 3
                    color: Theme.overlay
                    implicitHeight: hudRes.implicitHeight + 10
                    implicitWidth: hudRes.implicitWidth + 16

                    Text {
                        id: hudRes
                        anchors.centerIn: parent
                        text: form.previewWidth + "\u00D7" + form.previewHeight
                        color: Theme.hudDim
                        font.family: Theme.monoFont
                        font.pixelSize: 11
                    }
                }
            }

            // ---- Right column: data cards + controls -------------------
            // maximumWidth is required: a nested ColumnLayout containing
            // fillWidth children reports an infinite maximum width, which
            // would otherwise starve the fillWidth viewport (Qt layouts trap).
            ColumnLayout {
                Layout.preferredWidth: 250
                Layout.maximumWidth: 250
                Layout.alignment: Qt.AlignTop
                spacing: 14

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "POSITION"
                        color: Theme.textDim
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.5
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 6
                        columnSpacing: 10

                        Label { text: "X"; color: Theme.textDim; font.pixelSize: 12 }
                        LcdDisplay { value: posX; Layout.fillWidth: true }
                        Label { text: "Y"; color: Theme.textDim; font.pixelSize: 12 }
                        LcdDisplay { value: posY; Layout.fillWidth: true }
                        Label { text: "Z"; color: Theme.textDim; font.pixelSize: 12 }
                        LcdDisplay { value: posZ; Layout.fillWidth: true }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "POSE"
                        color: Theme.textDim
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.5
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 6
                        columnSpacing: 10

                        Label { text: "Yaw";   color: Theme.textDim; font.pixelSize: 12 }
                        LcdDisplay { value: poseYaw;   unit: "\u00B0"; Layout.fillWidth: true }
                        Label { text: "Pitch"; color: Theme.textDim; font.pixelSize: 12 }
                        LcdDisplay { value: posePitch; unit: "\u00B0"; Layout.fillWidth: true }
                        Label { text: "Roll";  color: Theme.textDim; font.pixelSize: 12 }
                        LcdDisplay { value: poseRoll;  unit: "\u00B0"; Layout.fillWidth: true }
                    }
                }

                Item { Layout.fillHeight: true }

                // Primary action: Start / Stop.
                Button {
                    id: start_button
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    enabled: !form.running
                    hoverEnabled: true

                    background: Rectangle {
                        radius: 4
                        color: !start_button.enabled ? Qt.darker(Theme.accent, 1.9)
                               : start_button.pressed ? Qt.darker(Theme.accent, 1.2)
                               : start_button.hovered ? Qt.lighter(Theme.accent, 1.1)
                               : Theme.accent
                    }
                    contentItem: Text {
                        text: "\u25B6  Start"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        // Disabled state keeps the darker(accent) navy fill in
                        // both themes -> light text per the dark-bg/light-text rule.
                        color: !start_button.enabled ? "#99E6E8EB" : Theme.textOnAccent
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                Button {
                    id: stop_button
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    enabled: form.running
                    hoverEnabled: true

                    // While running, Stop is filled red so it is easy to find;
                    // otherwise it stays a quiet outlined button.
                    background: Rectangle {
                        radius: 4
                        color: !stop_button.enabled ? "transparent"
                               : stop_button.pressed ? Qt.darker(Theme.error, 1.25)
                               : stop_button.hovered ? Qt.lighter(Theme.error, 1.15)
                               : Theme.error
                        border.width: 1
                        border.color: stop_button.enabled ? Theme.error : Theme.border
                    }
                    contentItem: Text {
                        text: "\u25A0  Stop"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: stop_button.enabled ? Theme.textOnError : Theme.textDim
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                // Secondary actions.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        id: preview_button
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        hoverEnabled: true

                        background: Rectangle {
                            radius: 4
                            color: preview_button.pressed ? Qt.lighter(Theme.input, 1.15)
                                   : preview_button.hovered ? Qt.lighter(Theme.input, 1.08)
                                   : Theme.input
                            border.width: 1
                            border.color: Theme.border
                        }
                        contentItem: Text {
                            text: "Preview"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: Theme.text
                            font.pixelSize: 12
                        }
                    }

                    Button {
                        id: center_button
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        hoverEnabled: true

                        background: Rectangle {
                            radius: 4
                            color: center_button.pressed ? Qt.lighter(Theme.input, 1.15)
                                   : center_button.hovered ? Qt.lighter(Theme.input, 1.08)
                                   : Theme.input
                            border.width: 1
                            border.color: Theme.border
                        }
                        contentItem: Text {
                            text: "Center"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: Theme.text
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }

        // ---- Collapsible log strip -------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: form.logExpanded ? 150 : 28
            color: Theme.panel
            radius: 4
            border.width: 1
            border.color: Theme.border

            Behavior on Layout.preferredHeight { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

            ColumnLayout {
                anchors.fill: parent
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 6
                    Layout.preferredHeight: 26

                    Label {
                        text: "LOG"
                        color: Theme.textDim
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.5
                    }
                    Item { Layout.fillWidth: true }

                    Button {
                        id: clear_log_button
                        visible: form.logExpanded
                        text: qsTr("Clear")
                        flat: true
                        hoverEnabled: true
                        contentItem: Text {
                            text: clear_log_button.text
                            color: clear_log_button.hovered ? Theme.text : Theme.textDim
                            font.pixelSize: 11
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: null
                    }

                    // Collapse / expand toggle.
                    Button {
                        id: log_toggle
                        flat: true
                        hoverEnabled: true
                        implicitWidth: 24
                        implicitHeight: 24
                        onClicked: form.logExpanded = !form.logExpanded

                        contentItem: Text {
                            text: form.logExpanded ? "\u25BC" : "\u25B2" // ▼ / ▲
                            color: log_toggle.hovered ? Theme.text : Theme.textDim
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: null
                    }
                }

                Flickable {
                    id: log_flick
                    visible: form.logExpanded
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.bottomMargin: 4
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
                        placeholderText: qsTr("No log messages yet.")
                        selectByMouse: true
                        color: Theme.textDim
                        font.family: "Consolas, Menlo, Monaco, monospace"
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
