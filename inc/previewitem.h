#ifndef PREVIEWITEM_H
#define PREVIEWITEM_H

#include <QQuickPaintedItem>
#include "foxcontroller.h"

// QML item that paints the latest camera preview frame supplied by the
// FoxController. Replaces the old VideoContainer QLabel-based widget.
class PreviewItem : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(FoxController *controller READ controller WRITE setController NOTIFY controllerChanged)

public:
    explicit PreviewItem(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;

    FoxController *controller() const { return m_controller; }
    void setController(FoxController *c);

signals:
    void controllerChanged();

private slots:
    void onFrameReady();

private:
    FoxController *m_controller = nullptr;
};

#endif // PREVIEWITEM_H
