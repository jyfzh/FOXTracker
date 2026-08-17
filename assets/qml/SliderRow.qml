import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

// Labeled slider bound to a real-valued setting (value in [from, to]).
// `value` is an alias to the inner Slider so the parent can both read the
// live position and push model values in. Changes are reported via
// `valueEdited(real v)`, emitted only on user interaction (onMoved).
RowLayout {
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
        from: parent.from
        to: parent.to
        stepSize: parent.stepSize
        Layout.fillWidth: true
        onMoved: parent.valueEdited(value)
    }
    Label { text: value.toFixed(decimals); Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight }
}
