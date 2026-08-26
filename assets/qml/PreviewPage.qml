import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import FOXTracker 1.0
import FOXTracker.Theme 1.0

PreviewPageForm {
    id: form

    // Bind live data from the FoxController context property
    posX: fox.x
    posY: fox.y
    posZ: fox.z
    poseYaw: fox.yaw
    posePitch: fox.pitch
    poseRoll: fox.roll
    previewController: fox
    running: fox.running
    fps: fox.fps
    previewWidth: fox.previewWidth
    previewHeight: fox.previewHeight
    readonly property int maxLogEntries: 5000

    ListModel { id: fullLog }

    function levelColor(level) {
        if (level === "DEBUG") return Theme.logDebug
        if (level === "WARN")  return Theme.warning
        if (level === "ERROR") return Theme.error
        if (level === "FATAL") return Theme.logFatal
        return Theme.text // INFO and anything else
    }

    function escapeHtml(s) {
        return s.replace(/&/g, "&amp;")
                .replace(/</g, "&lt;")
                .replace(/>/g, "&gt;")
                .replace(/\n/g, "<br>")
    }

    function lineHtml(time, level, message, color) {
        return '<font color="' + color + '">[' + level + ']</font> '
             + '<font color="' + Theme.textDim + '">' + time + '</font> '
             + escapeHtml(message)
    }

    function clearLog() {
        fullLog.clear()
        form.logView.clear()
    }

    function scrollToEnd() {
        form.logView.cursorPosition = form.logView.length
        var f = form.logFlick
        f.contentY = Math.max(0, f.contentHeight - f.height)
    }

    function appendLog(time, level, message) {
        var color = levelColor(level)
        fullLog.append({ time: time, level: level, message: message, color: color })
        // TextArea.append() inserts plain text, so build the rich text by
        // concatenation instead (otherwise the <font> tags show literally).
        form.logView.text += lineHtml(time, level, message, color)
        scrollToEnd()

        if (fullLog.count > maxLogEntries) {
            fullLog.remove(0, fullLog.count - maxLogEntries)
            rebuildLog() // trim and re-render the visible view
        }
    }

    function rebuildLog() {
        var html = ""
        for (var i = 0; i < fullLog.count; ++i) {
            var e = fullLog.get(i)
            html += lineHtml(e.time, e.level, e.message, e.color)
        }
        form.logView.text = html
        scrollToEnd()
    }

    function parseAndLog(msg) {
        var re = /^\[(\w+)\]\s*([\s\S]*)$/
        var m = re.exec(msg)
        var level = m ? m[1] : "INFO"
        var text  = m ? m[2] : msg
        var time  = Qt.formatTime(new Date(), "hh:mm:ss.zzz")
        appendLog(time, level, text)
    }

    Connections {
        target: logManager
        function onLogMessage(msg) { parseAndLog(msg) }
    }

    Connections {
        target: form.startButton
        function onClicked() { fox.start() }
    }

    Connections {
        target: form.stopButton
        function onClicked() { fox.stop() }
    }

    Connections {
        target: form.centerButton
        function onClicked() { fox.center() }
    }

    Connections {
        target: form.previewButton
        function onClicked() { fox.togglePreview() }
    }

    Connections {
        target: form.clearLogButton
        function onClicked() { clearLog() }
    }
}
