import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtCharts 2.2
import FOXTracker.Theme 1.0

// Pure declarative UI form for the EKF page.
// All logic (signal wiring, chart append, trim timer) lives in EkfPage.qml.
Page {
    id: form
    padding: 8

    property int sel: 0

    // Expose chart series / axes so the logic file can push data into them.
    property alias sYawP:   sYawP
    property alias sPitchP: sPitchP
    property alias sRollP:  sRollP
    property alias sXT:     sXT
    property alias sYT:     sYT
    property alias sZT:     sZT
    property alias sYawR:   sYawR
    property alias sPitchR: sPitchR
    property alias sRollR:  sRollR
    property alias sXTR:    sXTR
    property alias sYTR:    sYTR
    property alias sZTR:    sZTR
    property alias sYawW:   sYawW
    property alias sPitchW: sPitchW
    property alias sRollW:  sRollW
    property alias sXV:     sXV
    property alias sYV:     sYV
    property alias sZV:     sZV
    property alias axX: axX
    property alias ayY: ayY

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        GroupBox {
            title: "EKF Noise"
            Layout.fillWidth: true
            GridLayout {
                columns: 2
                rowSpacing: 4
                columnSpacing: 12
                LogSlider { label: "Q (LM)";   min: 0.001; max: 1.0;  norm: fox.qNoiseLM;  onNormEdited: fox.qNoiseLM = v }
                LogSlider { label: "Q (FSA)";  min: 0.001; max: 1.0;  norm: fox.qNoiseFSA; onNormEdited: fox.qNoiseFSA = v }
                LogSlider { label: "T Noise";  min: 0.001; max: 0.1;  norm: fox.tNoise;    onNormEdited: fox.tNoise = v }
                LogSlider { label: "V Noise";  min: 0.1;   max: 20.0; norm: fox.vNoise;    onNormEdited: fox.vNoise = v }
                LogSlider { label: "W Noise";  min: 0.1;   max: 30.0; norm: fox.wNoise;    onNormEdited: fox.wNoise = v }
            }
        }

        RowLayout {
            Label { text: "Chart:" }
            ComboBox {
                id: chartSel
                model: ["Yaw", "Pitch", "Roll", "X", "Y", "Z"]
                currentIndex: sel
                onActivated: sel = currentIndex
            }
        }

        ChartView {
            id: cv
            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: true
            backgroundColor: Theme.panel
            titleColor: Theme.textDim
            legend.visible: true
            legend.alignment: Qt.AlignBottom
            legend.labelColor: Theme.textDim

            ValueAxis {
                id: axX
                min: 0; max: 30; tickCount: 10
                labelsColor: Theme.textDim
                gridLineColor: Theme.border
            }
            ValueAxis {
                id: ayY
                min: -45; max: 45
                labelsColor: Theme.textDim
                gridLineColor: Theme.border
            }

            // Series colors are fixed to the semantic theme palette so the
            // chart remains legible in both dark and light themes.
            LineSeries { id: sYawP;   name: "Pose"; axisX: axX; axisY: ayY; visible: sel === 0; color: Theme.accent }
            LineSeries { id: sYawR;   name: "Raw";  axisX: axX; axisY: ayY; visible: sel === 0; color: Theme.warning }
            LineSeries { id: sYawW;   name: "Rate"; axisX: axX; axisY: ayY; visible: sel === 0; color: Theme.success }

            LineSeries { id: sPitchP; name: "Pose"; axisX: axX; axisY: ayY; visible: sel === 1; color: Theme.accent }
            LineSeries { id: sPitchR; name: "Raw";  axisX: axX; axisY: ayY; visible: sel === 1; color: Theme.warning }
            LineSeries { id: sPitchW; name: "Rate"; axisX: axX; axisY: ayY; visible: sel === 1; color: Theme.success }

            LineSeries { id: sRollP;  name: "Pose"; axisX: axX; axisY: ayY; visible: sel === 2; color: Theme.accent }
            LineSeries { id: sRollR;  name: "Raw";  axisX: axX; axisY: ayY; visible: sel === 2; color: Theme.warning }
            LineSeries { id: sRollW;  name: "Rate"; axisX: axX; axisY: ayY; visible: sel === 2; color: Theme.success }

            LineSeries { id: sXT;  name: "Pos"; axisX: axX; axisY: ayY; visible: sel === 3; color: Theme.accent }
            LineSeries { id: sXTR; name: "Raw"; axisX: axX; axisY: ayY; visible: sel === 3; color: Theme.warning }
            LineSeries { id: sXV;  name: "Vel"; axisX: axX; axisY: ayY; visible: sel === 3; color: Theme.success }

            LineSeries { id: sYT;  name: "Pos"; axisX: axX; axisY: ayY; visible: sel === 4; color: Theme.accent }
            LineSeries { id: sYTR; name: "Raw"; axisX: axX; axisY: ayY; visible: sel === 4; color: Theme.warning }
            LineSeries { id: sYV;  name: "Vel"; axisX: axX; axisY: ayY; visible: sel === 4; color: Theme.success }

            LineSeries { id: sZT;  name: "Pos"; axisX: axX; axisY: ayY; visible: sel === 5; color: Theme.accent }
            LineSeries { id: sZTR; name: "Raw"; axisX: axX; axisY: ayY; visible: sel === 5; color: Theme.warning }
            LineSeries { id: sZV;  name: "Vel"; axisX: axX; axisY: ayY; visible: sel === 5; color: Theme.success }
        }
    }
}
