import QtQuick
import QtQml

EkfPageForm {
    id: page

    property var tInit: null
    property double lastT: 0
    // Pending axis window: axes are updated on a throttled timer, not per point.
    property double _pendingT: 0
    property double _lastPoseT: -1e9
    property double _lastRawT: -1e9
    property double _lastTwistT: -1e9

    // 3 s window at ~30 Hz ≈ 90 pts; keep 120 for headroom.
    // 120 pts x 18 series = 2.1k points vs 18k before (~88% reduction).
    readonly property int maxPoints: 120
    // Defensive ~30 Hz cap per stream (C++ already throttles); keeps JS appends
    // bounded even if the backend throttle is bypassed.
    readonly property double minInterval: 0.033

    Component.onCompleted: {
        fox.chartPose.connect(onPose)
        fox.chartRawPose.connect(onRaw)
        fox.chartTwist.connect(onTwist)
    }

    function shouldAppendPose(t) {
        if (t - _lastPoseT < minInterval) return false
        _lastPoseT = t; return true
    }
    function shouldAppendRaw(t) {
        if (t - _lastRawT < minInterval) return false
        _lastRawT = t; return true
    }
    function shouldAppendTwist(t) {
        if (t - _lastTwistT < minInterval) return false
        _lastTwistT = t; return true
    }

    // Single O(n) removal instead of while(remove(0)) which is O(n*k).
    // Count cap + strict 3 s time window (whichever trims more).
    function trimOne(s) {
        if (s.count > maxPoints)
            s.removePoints(0, s.count - maxPoints)
        if (s.count === 0 || lastT === 0)
            return
        var cutoff = lastT - 3
        // s.at(0).x is the oldest timestamp; scan for first kept point
        if (s.at(0).x >= cutoff)
            return
        var n = 0
        // linear scan over at most ~120 points, once per 800 ms — negligible
        while (n < s.count && s.at(n).x < cutoff) ++n
        if (n > 0) s.removePoints(0, n)
    }
    function trimAll() {
        trimOne(page.sYawP); trimOne(page.sPitchP); trimOne(page.sRollP)
        trimOne(page.sXT);   trimOne(page.sYT);     trimOne(page.sZT)
        trimOne(page.sYawR); trimOne(page.sPitchR); trimOne(page.sRollR)
        trimOne(page.sXTR);  trimOne(page.sYTR);    trimOne(page.sZTR)
        trimOne(page.sYawW); trimOne(page.sPitchW); trimOne(page.sRollW)
        trimOne(page.sXV);   trimOne(page.sYV);     trimOne(page.sZV)
    }
    function updateAxes() {
        if (_pendingT === lastT)
            return
        _pendingT = lastT
        page.axX.min = Math.max(0, lastT - 3)
        page.axX.max = lastT + 0.2
        var angle = page.sel < 3
        page.ayY.min = angle ? -45 : -50
        page.ayY.max = angle ? 45 : 50
    }
    function onPose(t, yaw, pitch, roll, x, y, z) {
        lastT = t
        if (!shouldAppendPose(t))
            return
        if (tInit === null) tInit = [x, y, z]
        var dx = (x - tInit[0]) * 100, dy = (y - tInit[1]) * 100, dz = (z - tInit[2]) * 100
        page.sYawP.append(t, yaw);   page.sPitchP.append(t, pitch); page.sRollP.append(t, roll)
        page.sXT.append(t, dx);      page.sYT.append(t, dy);        page.sZT.append(t, dz)
    }
    function onRaw(t, yaw, pitch, roll, x, y, z) {
        lastT = t
        if (!shouldAppendRaw(t))
            return
        if (tInit === null) tInit = [x, y, z]
        var dx = (x - tInit[0]) * 100, dy = (y - tInit[1]) * 100, dz = (z - tInit[2]) * 100
        page.sYawR.append(t, yaw);   page.sPitchR.append(t, pitch); page.sRollR.append(t, roll)
        page.sXTR.append(t, dx);     page.sYTR.append(t, dy);       page.sZTR.append(t, dz)
    }
    function onTwist(t, wx, wy, wz, vx, vy, vz) {
        lastT = t
        if (!shouldAppendTwist(t))
            return
        page.sYawW.append(t, wz * 180 / Math.PI)
        page.sPitchW.append(t, wy * 180 / Math.PI)
        page.sRollW.append(t, wx * 180 / Math.PI)
        page.sXV.append(t, vx * 100); page.sYV.append(t, vy * 100); page.sZV.append(t, vz * 100)
    }

    // Axis window slides at ~10 Hz; avoids layout/relayout on every point.
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: updateAxes()
    }
    // Trim in larger batches less often; removePoints is O(n) once.
    Timer {
        interval: 800
        running: true
        repeat: true
        onTriggered: trimAll()
    }
}
