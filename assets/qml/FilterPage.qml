import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Page {
    id: page
    padding: 8
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: 10

            GroupBox {
                title: "Rotation"
                Layout.fillWidth: true
                GridLayout {
                    columns: 2
                    rowSpacing: 4
                    columnSpacing: 16
                    SliderRow { label: "Smoothing";   from: 0.01; to: 0.3;  value: fox.rotSmooth;    onValueEdited: fox.rotSmooth = v }
                    SliderRow { label: "Deadzone";    from: 0.01; to: 6.0;  value: fox.rotDeadzone;  onValueEdited: fox.rotDeadzone = v }
                    SliderRow { label: "Expo Yaw";    from: 0; to: 1; decimals: 2; value: fox.rotExpoYaw;   onValueEdited: fox.rotExpoYaw = v }
                    SliderRow { label: "Expo Pitch";  from: 0; to: 1; decimals: 2; value: fox.rotExpoPitch; onValueEdited: fox.rotExpoPitch = v }
                    SliderRow { label: "Expo Roll";   from: 0; to: 1; decimals: 2; value: fox.rotExpoRoll;  onValueEdited: fox.rotExpoRoll = v }
                    SliderRow { label: "In Max Yaw";  from: 10; to: 45; decimals: 1; value: fox.rotInYaw;  onValueEdited: fox.rotInYaw = v }
                    SliderRow { label: "In Max Pitch";from: 10; to: 45; decimals: 1; value: fox.rotInPitch;onValueEdited: fox.rotInPitch = v }
                    SliderRow { label: "In Max Roll"; from: 10; to: 45; decimals: 1; value: fox.rotInRoll; onValueEdited: fox.rotInRoll = v }
                    SliderRow { label: "Out Max Yaw"; from: 30; to: 180;decimals: 1; value: fox.rotOutYaw;  onValueEdited: fox.rotOutYaw = v }
                    SliderRow { label: "Out Max Pitch";from: 30;to: 180;decimals: 1; value: fox.rotOutPitch;onValueEdited: fox.rotOutPitch = v }
                    SliderRow { label: "Out Max Roll";from: 30; to: 180;decimals: 1; value: fox.rotOutRoll; onValueEdited: fox.rotOutRoll = v }
                }
            }

            GroupBox {
                title: "Translation"
                Layout.fillWidth: true
                GridLayout {
                    columns: 2
                    rowSpacing: 4
                    columnSpacing: 16
                    SliderRow { label: "Smoothing";   from: 0.01; to: 0.2;  value: fox.transSmooth;    onValueEdited: fox.transSmooth = v }
                    SliderRow { label: "Deadzone";    from: 0.0;  to: 0.2;  value: fox.transDeadzone;  onValueEdited: fox.transDeadzone = v }
                    SliderRow { label: "Expo X";      from: 0; to: 1; decimals: 2; value: fox.transExpoX; onValueEdited: fox.transExpoX = v }
                    SliderRow { label: "Expo Y";      from: 0; to: 1; decimals: 2; value: fox.transExpoY; onValueEdited: fox.transExpoY = v }
                    SliderRow { label: "Expo Z";      from: 0; to: 1; decimals: 2; value: fox.transExpoZ; onValueEdited: fox.transExpoZ = v }
                    SliderRow { label: "In Max X";    from: 0.10; to: 1.0; decimals: 2; value: fox.transInX; onValueEdited: fox.transInX = v }
                    SliderRow { label: "In Max Y";    from: 0.10; to: 1.0; decimals: 2; value: fox.transInY; onValueEdited: fox.transInY = v }
                    SliderRow { label: "In Max Z";    from: 0.10; to: 1.0; decimals: 2; value: fox.transInZ; onValueEdited: fox.transInZ = v }
                    SliderRow { label: "Out Max X";   from: 0.30; to: 1.0; decimals: 2; value: fox.transOutX; onValueEdited: fox.transOutX = v }
                    SliderRow { label: "Out Max Y";   from: 0.30; to: 1.0; decimals: 2; value: fox.transOutY; onValueEdited: fox.transOutY = v }
                    SliderRow { label: "Out Max Z";   from: 0.30; to: 1.0; decimals: 2; value: fox.transOutZ; onValueEdited: fox.transOutZ = v }
                }
            }

            GroupBox {
                title: "Accela Filter"
                Layout.fillWidth: true
                ColumnLayout {
                    CheckBox { text: "Enable Accela"; checked: fox.useAccela; onToggled: fox.useAccela = checked }
                    CheckBox { text: "Double Accela"; checked: fox.doubleAccela; onToggled: fox.doubleAccela = checked }
                }
            }
        }
    }
}
