import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Labeled slider bound to a real-valued setting (value in [from, to]).
// `value` is an alias to the inner Slider so the parent can both read the
// live position and push model values in. Changes are reported via
// `valueEdited(real v)`, emitted only on user interaction (onMoved).
RowLayout {
    id: root
    property string label: ""
    property alias value: slider.value
    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    property int decimals: 3
    signal valueEdited(real v)

    Label { text: label; Layout.preferredWidth: 100; elide: Text.ElideRight }
    Slider {
        id: slider
        from: root.from
        to: root.to
        stepSize: root.stepSize
        Layout.fillWidth: true
        onMoved: root.valueEdited(value)
    }
    Label { text: root.value.toFixed(root.decimals); Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            if (!slider.enabled) return
            var delta = event.angleDelta.y
            if (delta === 0) return
            var step = slider.stepSize !== 0 ? slider.stepSize : (slider.to - slider.from) / 100
            var steps = Math.round(delta / 120)
            var newVal = slider.value + steps * step
            newVal = Math.max(slider.from, Math.min(slider.to, newVal))
            if (newVal !== slider.value) {
                slider.value = newVal
                root.valueEdited(newVal)
            }
            event.accepted = true
        }
    }
}
