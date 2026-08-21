import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Item {
    id: form
    implicitWidth: 904
    implicitHeight: 675

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: status
            z: 100
            Layout.fillWidth: true
            height: 20
            Text {
                text: "current status"
            }
        }

        TabBar {
            id: tabBar
            Layout.fillWidth: true
            TabButton {
                text: "Preview"
            }
            TabButton {
                text: "EKF"
            }
            TabButton {
                text: "Filter"
            }
            TabButton {
                text: "Setting"
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // Preview page
            PreviewPage {}
            // EKF config page
            EkfPage {}
            // Filter config page
            FilterPage {}
            // Setting config page
            SettingPage {}
        }
    }
}
