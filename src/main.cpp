#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFontDatabase>
#include <QDebug>
#include <QtQuickControls2/qquickstyle.h>

#include "foxcontroller.h"
#include "previewitem.h"
#include "ThemeManager.h"
#include "FlightAgxSettings.h"
#include "LogManager.h"

FlightAgxSettings * settings = nullptr;

int main(int argc, char *argv[])
{
    qRegisterMetaType<Pose_>("Pose_");
    qRegisterMetaType<Pose6DoF>("Pose6DoF");
    qRegisterMetaType<Eigen::Vector3d>("Eigen::Vector3d");
    qRegisterMetaType<Matrix19d>("Matrix19d");

    // Note: high-DPI scaling is enabled by default since Qt 6
    // (AA_EnableHighDpiScaling no longer exists).

    // QApplication (not QGuiApplication) is required because the legacy
    // EKF/Filter/Setting configuration widgets are still QWidget-based and are
    // embedded into the QML scene via QWidget::createWindowContainer.
    QApplication a(argc, argv);

    // Fusion follows the application palette, which gives both the QML scene
    // and the legacy embedded QWidget pages a consistent look in any theme.
    QQuickStyle::setStyle("Fusion");

    // ThemeManager owns the light/dark/system color theme: it applies the
    // matching QApplication palette (picked up by Fusion + embedded QWidgets)
    // and exposes the resolved dark state to QML via FOXTracker.ThemeManager,
    // which assets/qml/Theme.qml maps onto concrete colors.
    qmlRegisterSingletonType<ThemeManager>(
        "FOXTracker.ThemeManager", 1, 0, "ThemeManager",
        [](QQmlEngine *, QJSEngine *) -> QObject * {
            return new ThemeManager; // the QML engine takes ownership
        });

    qmlRegisterType<PreviewItem>("FOXTracker", 1, 0, "PreviewView");
    qmlRegisterSingletonType(QUrl("qrc:/qml/Theme.qml"), "FOXTracker.Theme", 1, 0, "Theme");



    settings = new FlightAgxSettings;

    QQmlApplicationEngine engine;
    FoxController controller;
    engine.rootContext()->setContextProperty("fox", &controller);
    LogManager logManager;
    engine.rootContext()->setContextProperty("logManager", &logManager);
    engine.load(QUrl("qrc:/qml/MainWindow.qml"));
    if (engine.rootObjects().isEmpty())
        return -1;

    return a.exec();
}
