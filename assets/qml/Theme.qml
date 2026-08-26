pragma Singleton
import QtQuick 2.12
import FOXTracker.ThemeManager 1.0

// Adaptive theme shared by all QML files.
// The mode ("system"/"light"/"dark") lives in the C++ ThemeManager singleton
// and is persisted in config.yaml as "ui_theme"; this singleton maps the
// resolved dark flag onto concrete colors, so every binding updates live when
// the theme changes. Registered from main.cpp under FOXTracker.Theme.
//
// Colors are intentionally typed `string` (not `color`) so they can be handed
// to a ListModel / concatenated into HTML (`<font color="...">`) without the
// QML engine turning a `color` value into a VariantMap. Assigning these
// strings to a `color:` property (or to Qt.darker/lighter) still converts
// automatically, so rendering is unchanged.
QtObject {
    readonly property bool dark: ThemeManager.dark

    readonly property string background: dark ? "#1E1F22" : "#EFF1F4"
    readonly property string panel:      dark ? "#282A2E" : "#F7F8FA"
    readonly property string input:      dark ? "#303238" : "#FFFFFF"
    readonly property string border:     dark ? "#41434A" : "#D5D9E0"

    readonly property string text:       dark ? "#E6E8EB" : "#1B1D21"
    readonly property string textDim:    dark ? "#9298A3" : "#5A6270"

    readonly property string accent:     dark ? "#4DA3FF" : "#1E6FD9"
    readonly property string success:    dark ? "#46C78A" : "#189A58"
    readonly property string warning:    dark ? "#E5B84B" : "#B07D10"
    readonly property string error:      dark ? "#E05D6F" : "#C43D50"

    // Semantic aliases derived from the palette above — kept here so no file
    // hardcodes a hex value. Changing a color in one place updates every
    // consumer (buttons, HUD overlays, log view, viewport, charts).
    // NOTE: names must not start with `on` + Capital — QML would parse them as
    // signal handlers ("Cannot assign a value to a signal") and break this file.
    readonly property string textOnAccent: dark ? "#10151C" : "#FFFFFF"
    readonly property string textOnError:  "#FFFFFF"
    // Translucent backdrop for the viewport HUD chips (tracking state, FPS,
    // resolution) over the live video. Derived from the theme's `panel` color
    // (~75–80% alpha), so the chip background visibly follows the theme:
    // dark-tinted card in dark mode, light-tinted one in light mode, keeping
    // the themed chip text readable on top of camera footage.
    readonly property string overlay:    dark ? "#BF282A2E" : "#CCF7F8FA" // panel @ 75%/80% alpha
    readonly property string viewportBg: dark ? "#101114" : "#E9EBEF"
    readonly property string logDebug:   dark ? "#8b949e" : "#6e7681"
    readonly property string logFatal:   dark ? "#FF97A3" : "#B23246"

    // Viewport HUD chip text (tracking state, FPS, resolution). Aliases of the
    // main palette: the chips now sit on a theme-adaptive `overlay` scrim, so
    // the text follows the theme too instead of staying frozen at dark values.
    readonly property string hudText:    text
    readonly property string hudDim:     textDim
    readonly property string hudSuccess: success

    readonly property string monoFont:  "Consolas"
}
