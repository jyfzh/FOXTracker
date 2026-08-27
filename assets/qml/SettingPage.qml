import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FOXTracker.ThemeManager 1.0

// Logic/controller for the Setting page. The pure UI declaration is in
// SettingPageForm.ui.qml.
SettingPageForm {
    id: page

    // Theme mode ("system"/"light"/"dark") lives in the C++ ThemeManager
    // singleton. The .ui.qml form must not import C++ singleton types directly
    // (that raises "ThemeManager is not defined" at runtime), so the wiring is
    // done here in the logic layer.
    readonly property var themeValues: ["system", "light", "dark"]

    Binding {
        target: page.themeComboBox
        property: "currentIndex"
        value: themeValues.indexOf(ThemeManager.mode)
    }

    Connections {
        target: page.themeComboBox
        function onActivated(index) { ThemeManager.mode = themeValues[index] }
    }
}
