#pragma once
#include <QtGlobal>
#include <QObject>
#include <QStringList>
#include <QIODevice>
#include <QStringDecoder>
#include <QStringConverter>
#include <QRegularExpression>

class CSV
{
public:
    QString readLine();
    bool parseLine(QStringList& ret);

    static bool getGameData(int gameID, unsigned char* table, QString csv_path, QString& gamename);
private:
    CSV(QIODevice* device);

    QIODevice* m_device;
    QString m_string;
    int m_pos;

    static const QRegularExpression m_rx, m_rx2;
};
