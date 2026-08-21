import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

// Logic/controller for the Preview page. The pure UI declaration is in
// PreviewPageForm.ui.qml. This file binds the 'fox' context property
// to the form's properties, since .ui.qml files cannot access context properties directly.
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
}
