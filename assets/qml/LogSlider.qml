import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Labeled slider whose position is a normalized 0..1 value but displays the
// actual (log-mapped) quantity, used for EKF noise covariances.
RowLayout {
    id: root
    property string label: ""
    property real norm: 0
    property real min: 0.001
    property real max: 1.0
    signal normEdited(real v)

    Label { text: label; Layout.preferredWidth: 120 }
    Slider {
        id: slider
        from: 0
        to: 1
        stepSize: 0.01
        value: root.norm
        Layout.fillWidth: true
        onMoved: root.normEdited(value)
    }
    Label { text: (root.min * Math.exp(root.norm * Math.log(root.max / root.min))).toFixed(4); Layout.preferredWidth: 72; horizontalAlignment: Text.AlignRight }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            if (!slider.enabled) return
            var delta = event.angleDelta.y
            if (delta === 0) return
            var step = 0.01
            var steps = Math.round(delta / 120)
            var newVal = slider.value + steps * step
            newVal = Math.max(0, Math.min(1, newVal))
            if (newVal !== slider.value) {
                slider.value = newVal
                root.normEdited(newVal)
            }
            event.accepted = true
        }
    }
}
