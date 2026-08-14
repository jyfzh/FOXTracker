#include "mainwindow.h"
#include "HeadPoseDetector.h"
#include <QApplication>
#include <opencv2/opencv.hpp>
#include <QDebug>
#include "FlightAgxSettings.h"
#include <QFontDatabase>

FlightAgxSettings * settings = nullptr;

int main(int argc, char *argv[])
{
    qRegisterMetaType<Pose_>("Pose_");
    qRegisterMetaType<Pose6DoF>("Pose6DoF");
    qRegisterMetaType<Eigen::Vector3d>("Eigen::Vector3d");
    qRegisterMetaType<Matrix19d>("Matrix19d");

    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication a(argc, argv);

    QFontDatabase::addApplicationFont( QCoreApplication::applicationDirPath() + "/assets/SourceCodeVariable-Italic.ttf");
    QFontDatabase::addApplicationFont( QCoreApplication::applicationDirPath() + "/assets/SourceCodeVariable-Roman.ttf");

    a.setStyleSheet(R"(
        QWidget {
            font-family: "Microsoft YaHei";
            font-size: 14px;
            color: #333333;
            background-color: #f5f5f5;
        }

        QPushButton {
            background-color: #3498db;
            color: white;
            border-radius: 5px;
            padding: 6px 12px;
        }

        QPushButton:hover {
            background-color: #2980b9;
        }

        QLineEdit {
            background-color: white;
            border: 1px solid #cccccc;
            border-radius: 4px;
            padding: 5px;
        }

        QLabel {
            color: #555555;
        }
    )");

    settings = new FlightAgxSettings;

    MainWindow w;
    w.show();
    return a.exec();
}
