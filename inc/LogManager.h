#pragma once

#include <QObject>
#include <QDebug>

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
};