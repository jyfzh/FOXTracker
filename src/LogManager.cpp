// LogManager.cpp

#include "LogManager.h"
#include <QDateTime>

static LogManager *g_logManager = nullptr;

QMutex LogManager::s_suppressMutex;
QHash<QByteArray, qint64> LogManager::s_lastSeen;

LogManager::LogManager(QObject *parent)
    : QObject(parent)
{
    g_logManager = this;

    qInstallMessageHandler(LogManager::messageHandler);
}

// 必须在 QObject 本体被销毁之前卸载消息处理器并清空全局指针。
// 否则其他线程在日志输出时仍会通过悬空的 g_logManager 发射信号
// （use-after-free，曾导致 Qt5Qml!QQmlData::isSignalConnected 访问违例崩溃）。
LogManager::~LogManager()
{
    qInstallMessageHandler(nullptr);
    g_logManager = nullptr;
}


void LogManager::messageHandler(QtMsgType type,
                                const QMessageLogContext &context,
                                const QString &msg)
{
    QString level;

    switch(type) {
    case QtDebugMsg:
        level = "DEBUG";
        break;
    case QtWarningMsg:
        level = "WARN";
        break;
    case QtCriticalMsg:
        level = "ERROR";
        break;
    case QtFatalMsg:
        level = "FATAL";
        break;
    default:
        level = "INFO";
    }

    QString log = QString("[%1] %2")
                      .arg(level)
                      .arg(msg);

    // 保留原来的控制台输出
    fprintf(stderr, "%s\n", log.toLocal8Bit().data());

    if(g_logManager) {
        // Drop duplicate/repeated lines to protect the GUI event loop from
        // being flooded by a runaway debug stream (see kSuppressMs). A flood
        // would otherwise queue thousands of logMessage events per second and
        // stall preview/chart updates — the "slows down over time" symptom.
        bool forward = true;
        {
            QMutexLocker lock(&s_suppressMutex);
            QByteArray key = (level + msg).toUtf8();
            qint64 now = QDateTime::currentMSecsSinceEpoch();
            auto it = s_lastSeen.find(key);
            if (it != s_lastSeen.end() && now - it.value() < kSuppressMs) {
                forward = false;
            } else {
                s_lastSeen[key] = now;
            }
        }
        if (forward)
            emit g_logManager->logMessage(log);
    }
}