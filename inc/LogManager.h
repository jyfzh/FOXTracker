#pragma once

#include <QObject>
#include <QDebug>
#include <QMutex>
#include <QHash>

class LogManager : public QObject
{
    Q_OBJECT

public:
    explicit LogManager(QObject *parent = nullptr);
    ~LogManager() override;

    static void messageHandler(QtMsgType type,
                               const QMessageLogContext &context,
                               const QString &msg);

signals:
    void logMessage(QString msg);

private:
    // Suppress bursts of identical log lines so a runaway debug loop (e.g.
    // face-detection failing every frame) cannot flood the GUI event queue
    // and stall the whole UI. The same message is forwarded at most once per
    // suppression window; everything else is dropped.
    static constexpr qint64 kSuppressMs = 1000;
    static QMutex s_suppressMutex;
    static QHash<QByteArray, qint64> s_lastSeen;
};
