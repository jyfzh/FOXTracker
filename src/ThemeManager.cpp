#include "ThemeManager.h"

#include <QApplication>
#include <QDebug>
#include <QEvent>
#include <QGuiApplication>
#include <QWindow>

#include "FlightAgxSettings.h"

extern FlightAgxSettings *settings;

#ifdef Q_OS_WIN
#include <windows.h>
#include <dwmapi.h>
// Present in dwmapi.h from the Win10 1903 SDK onward; define for older ones.
#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif
#endif

ThemeManager::ThemeManager(QObject *parent)
    : QObject(parent)
{
    // Restore the persisted mode ("system"/"light"/"dark"); fall back to
    // "system" when the config is missing or has an invalid value.
    if (settings && !settings->ui_theme.empty())
    {
        const QString saved = QString::fromStdString(settings->ui_theme).toLower();
        if (saved == "light" || saved == "dark" || saved == "system")
            m_mode = saved;
    }

    // Follow OS light/dark switches while in "system" mode. Qt 5 has no
    // cross-platform colorScheme API, so poll the Windows registry cheaply.
    connect(&m_systemPollTimer, &QTimer::timeout, this, &ThemeManager::refreshSystemDark);
    m_systemPollTimer.start(2000);

    // This singleton is instantiated while loading MainWindow.qml, i.e. before
    // the window is shown; watch later windows so their title bar matches too.
    qApp->installEventFilter(this);

    resolveAndApply(true);
}

void ThemeManager::setMode(const QString &mode)
{
    const QString m = mode.toLower().trimmed();
    if (m != "system" && m != "light" && m != "dark")
    {
        qWarning() << "ThemeManager: invalid mode" << mode;
        return;
    }
    if (m == m_mode)
        return;
    m_mode = m;
    emit modeChanged();

    // Persist immediately (memory + yaml node + disk): the theme is a UI
    // preference that must survive an app restart without requiring the
    // "Save Config" button.
    if (settings)
    {
        settings->ui_theme = m.toStdString();
        settings->set_value<std::string>("ui_theme", settings->ui_theme);
        settings->write_to_file();
    }
    resolveAndApply();
}

bool ThemeManager::targetDark() const
{
    if (m_mode == "light")
        return false;
    if (m_mode == "dark")
        return true;
#ifdef Q_OS_WIN
    return systemPrefersDark();
#else
    return false;
#endif
}

void ThemeManager::resolveAndApply(bool force)
{
    const bool d = targetDark();
    if (d != m_dark)
    {
        m_dark = d;
        emit darkChanged();
    }
    if (!force && d == m_applied)
        return;
    m_applied = d;

    // The application palette drives both the Fusion QML style and every
    // embedded QWidget page, so one setPalette keeps everything consistent.
    qApp->setPalette(makePalette(d));

    applyTitleBarToAllWindows();
}

void ThemeManager::refreshSystemDark()
{
    resolveAndApply();
}

// Restrained palettes (see PLAN.md section 7):
// gray surfaces + blue accent + green status light, mirrored for light mode.
QPalette ThemeManager::makePalette(bool dark)
{
    QPalette pal;

    QColor bg, panel, input, text, dim, accent, highlightedText;
    QColor toolTipBase;
    if (dark)
    {
        bg = QColor(0x1E, 0x1F, 0x22);
        panel = QColor(0x28, 0x2A, 0x2E);
        input = QColor(0x30, 0x32, 0x38);
        text = QColor(0xE6, 0xE8, 0xEB);
        dim = QColor(0x92, 0x98, 0xA3);
        accent = QColor(0x4D, 0xA3, 0xFF);
        highlightedText = bg;
        toolTipBase = panel;
    }
    else
    {
        bg = QColor(0xEF, 0xF1, 0xF4);    // window background
        panel = QColor(0xF7, 0xF8, 0xFA); // panels / buttons / toolbar
        input = QColor(0xFF, 0xFF, 0xFF); // text fields / cards
        text = QColor(0x1B, 0x1D, 0x21);
        dim = QColor(0x5A, 0x62, 0x70);
        accent = QColor(0x1E, 0x6F, 0xD9);
        highlightedText = Qt::white;
        toolTipBase = QColor(0xFC, 0xFD, 0xFE);
    }

    pal.setColor(QPalette::Window, bg);
    pal.setColor(QPalette::WindowText, text);
    pal.setColor(QPalette::Base, input);
    pal.setColor(QPalette::AlternateBase, panel);
    pal.setColor(QPalette::Text, text);
    pal.setColor(QPalette::PlaceholderText, dim);
    pal.setColor(QPalette::Button, panel);
    pal.setColor(QPalette::ButtonText, text);
    pal.setColor(QPalette::BrightText, Qt::white);
    pal.setColor(QPalette::ToolTipBase, toolTipBase);
    pal.setColor(QPalette::ToolTipText, text);
    pal.setColor(QPalette::Highlight, accent);
    pal.setColor(QPalette::HighlightedText, highlightedText);
    pal.setColor(QPalette::Link, accent);
    pal.setColor(QPalette::Disabled, QPalette::Window, bg);
    pal.setColor(QPalette::Disabled, QPalette::WindowText, dim);
    pal.setColor(QPalette::Disabled, QPalette::Text, dim);
    pal.setColor(QPalette::Disabled, QPalette::ButtonText, dim);
    return pal;
}

// The QML scene follows Theme.background, but on Windows the native title bar
// ignores the Qt palette and would stay light in dark mode unless we tell DWM
// explicitly via DWMWA_USE_IMMERSIVE_DARK_MODE.
void ThemeManager::applyTitleBarToAllWindows()
{
    const QList<QWindow *> windows = QGuiApplication::topLevelWindows();
    for (QWindow *window : windows)
    {
        if (window->isVisible())
            applyTitleBar(window);
    }
}

void ThemeManager::applyTitleBar(QWindow *window)
{
#ifdef Q_OS_WIN
    if (!window || window->parent())
        return; // popups / child windows have no title bar of their own

    HWND hwnd = reinterpret_cast<HWND>(window->winId());
    const BOOL dark = m_dark ? TRUE : FALSE;
    // Attribute 20 works since Win10 1903; build 1809 shipped it as 19.
    if (FAILED(DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE,
                                     &dark, sizeof(dark))))
        DwmSetWindowAttribute(hwnd, 19, &dark, sizeof(dark));
#else
    Q_UNUSED(window)
#endif
}

bool ThemeManager::eventFilter(QObject *watched, QEvent *event)
{
    if (event->type() == QEvent::Show)
    {
        if (QWindow *window = qobject_cast<QWindow *>(watched))
            applyTitleBar(window);
    }
    return QObject::eventFilter(watched, event);
}

#ifdef Q_OS_WIN
// HKCU\...\Themes\Personalize\AppsUseLightTheme: 0 = apps use dark mode.
bool ThemeManager::systemPrefersDark()
{
    HKEY key = nullptr;
    if (RegOpenKeyExW(HKEY_CURRENT_USER,
                      L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
                      0, KEY_QUERY_VALUE, &key) != ERROR_SUCCESS)
        return true; // keep the traditional look when unknown

    DWORD value = 1, size = sizeof(value);
    RegQueryValueExW(key, L"AppsUseLightTheme", nullptr, nullptr,
                     reinterpret_cast<LPBYTE>(&value), &size);
    RegCloseKey(key);
    return value == 0;
}
#endif
