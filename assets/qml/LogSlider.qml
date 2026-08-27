import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Labeled slider whose position is a normalized 0..1 value but displays the
// actual (log-mapped) quantity, used for EKF noise covariances.
RowLayout {
    property string label: ""
    property real norm: 0
    property real min: 0.001
    property real max: 1.0
    signal normEdited(real v)

    Label { text: label; Layout.preferredWidth: 120 }
    Slider {
        from: 0
        to: 1
        stepSize: 0.01
        value: parent.norm
        Layout.fillWidth: true
        onMoved: parent.normEdited(value)
    }
    Label { text: (parent.min * Math.exp(parent.norm * Math.log(parent.max / parent.min))).toFixed(4); Layout.preferredWidth: 72; horizontalAlignment: Text.AlignRight }
}
