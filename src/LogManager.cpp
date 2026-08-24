// LogManager.cpp

#include "LogManager.h"

static LogManager *g_logManager = nullptr;

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

    if(g_logManager)
        emit g_logManager->logMessage(log);
}