#ifndef THEMEMANAGER_H
#define THEMEMANAGER_H

#include <QObject>
#include <QEvent>
#include <QTimer>
#include <QPalette>

class QWindow;

// Owns the UI color theme: "system" | "light" | "dark".
//
// - Applies a matching QPalette to the QApplication, so both the Fusion-styled
//   QML controls and the legacy embedded QWidget pages follow the theme.
// - Exposes the resolved dark state to QML as the FOXTracker.ThemeManager
//   singleton; assets/qml/Theme.qml maps it onto concrete colors.
// - The chosen mode is persisted in config.yaml as "ui_theme" via
//   FlightAgxSettings.
class ThemeManager : public QObject {
    Q_OBJECT
    // "system", "light" or "dark"
    Q_PROPERTY(QString mode READ mode WRITE setMode NOTIFY modeChanged)
    // Effective dark flag after resolving "system" against the OS setting
    Q_PROPERTY(bool dark READ dark NOTIFY darkChanged)

public:
    explicit ThemeManager(QObject *parent = nullptr);

    QString mode() const { return m_mode; }
    void setMode(const QString &mode);

    bool dark() const { return m_dark; }

signals:
    void modeChanged();
    void darkChanged();

protected:
    // Watches for top-level windows being shown (the singleton exists before
    // MainWindow does) so their native title bar gets the matching theme.
    bool eventFilter(QObject *watched, QEvent *event) override;

private slots:
    // Re-reads the OS preference and re-applies if it changed. Cheap enough
    // to poll; Qt 5 offers no cross-platform signal for this.
    void refreshSystemDark();

private:
    bool targetDark() const;
    void resolveAndApply(bool force = false);
    static QPalette makePalette(bool dark);
    // Makes the native window title bar follow the app theme (a no-op where
    // the OS does not support it): without this the frame stays light in dark
    // mode because DWM ignores the Qt palette.
    void applyTitleBarToAllWindows();
    void applyTitleBar(QWindow *window);
#ifdef Q_OS_WIN
    static bool systemPrefersDark();
#endif

    QString m_mode = QStringLiteral("system");
    bool m_dark = true;
    bool m_applied = false;
    QTimer m_systemPollTimer;
};

#endif // THEMEMANAGER_H
