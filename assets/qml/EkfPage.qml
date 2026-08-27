import QtQuick
import QtQml

EkfPageForm {
    id: page

    property var tInit: null
    property double lastT: 0

    Component.onCompleted: {
        fox.chartPose.connect(onPose)
        fox.chartRawPose.connect(onRaw)
        fox.chartTwist.connect(onTwist)
    }

    function trimOne(s) { while (s.count > 1000) s.remove(0) }
    function trimAll() {
        [page.sYawP, page.sPitchP, page.sRollP, page.sXT, page.sYT, page.sZT,
         page.sYawR, page.sPitchR, page.sRollR, page.sXTR, page.sYTR, page.sZTR,
         page.sYawW, page.sPitchW, page.sRollW, page.sXV, page.sYV, page.sZV].forEach(trimOne)
    }
    function updateAxes() {
        page.axX.min = Math.max(0, lastT - 30)
        page.axX.max = lastT + 1
        var angle = page.sel < 3
        page.ayY.min = angle ? -45 : -50
        page.ayY.max = angle ? 45 : 50
    }
    function onPose(t, yaw, pitch, roll, x, y, z) {
        if (tInit === null) tInit = [x, y, z]
        var dx = (x - tInit[0]) * 100, dy = (y - tInit[1]) * 100, dz = (z - tInit[2]) * 100
        page.sYawP.append(t, yaw);   page.sPitchP.append(t, pitch); page.sRollP.append(t, roll)
        page.sXT.append(t, dx);      page.sYT.append(t, dy);        page.sZT.append(t, dz)
        lastT = t; updateAxes()
    }
    function onRaw(t, yaw, pitch, roll, x, y, z) {
        if (tInit === null) tInit = [x, y, z]
        var dx = (x - tInit[0]) * 100, dy = (y - tInit[1]) * 100, dz = (z - tInit[2]) * 100
        page.sYawR.append(t, yaw);   page.sPitchR.append(t, pitch); page.sRollR.append(t, roll)
        page.sXTR.append(t, dx);     page.sYTR.append(t, dy);       page.sZTR.append(t, dz)
        lastT = t; updateAxes()
    }
    function onTwist(t, wx, wy, wz, vx, vy, vz) {
        page.sYawW.append(t, wz * 180 / Math.PI)
        page.sPitchW.append(t, wy * 180 / Math.PI)
        page.sRollW.append(t, wx * 180 / Math.PI)
        page.sXV.append(t, vx * 100); page.sYV.append(t, vy * 100); page.sZV.append(t, vz * 100)
        lastT = t; updateAxes()
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: trimAll()
    }
}
