#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFontDatabase>
#include <QDebug>

#include "foxcontroller.h"
#include "previewitem.h"
#include "FlightAgxSettings.h"

FlightAgxSettings * settings = nullptr;

int main(int argc, char *argv[])
{
    qRegisterMetaType<Pose_>("Pose_");
    qRegisterMetaType<Pose6DoF>("Pose6DoF");
    qRegisterMetaType<Eigen::Vector3d>("Eigen::Vector3d");
    qRegisterMetaType<Matrix19d>("Matrix19d");

    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    // QApplication (not QGuiApplication) is required because the legacy
    // EKF/Filter/Setting configuration widgets are still QWidget-based and are
    // embedded into the QML scene via QWidget::createWindowContainer.
    QApplication a(argc, argv);

    QFontDatabase::addApplicationFont( QCoreApplication::applicationDirPath() + "/assets/SourceCodeVariable-Italic.ttf");
    QFontDatabase::addApplicationFont( QCoreApplication::applicationDirPath() + "/assets/SourceCodeVariable-Roman.ttf");

    qmlRegisterType<PreviewItem>("FOXTracker", 1, 0, "PreviewView");

    settings = new FlightAgxSettings;

    QQmlApplicationEngine engine;
    FoxController controller;
    engine.rootContext()->setContextProperty("fox", &controller);
    engine.load(QUrl("qrc:/qml/main.qml"));
    if (engine.rootObjects().isEmpty())
        return -1;

    return a.exec();
}
