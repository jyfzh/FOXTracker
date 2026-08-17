#include "previewitem.h"
#include <QPainter>

PreviewItem::PreviewItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setRenderTarget(QQuickPaintedItem::FramebufferObject);
}

void PreviewItem::paint(QPainter *painter)
{
    QRectF rect = boundingRect();
    painter->fillRect(rect, Qt::black);
    if (m_controller == nullptr) {
        return;
    }
    QImage img = m_controller->previewImage();
    if (img.isNull()) {
        return;
    }
    QImage scaled = img.scaled(rect.size().toSize(),
                               Qt::KeepAspectRatio, Qt::SmoothTransformation);
    QPointF offset = rect.center() - QRectF(scaled.rect()).center();
    painter->drawImage(offset, scaled);
}

void PreviewItem::setController(FoxController *c)
{
    if (m_controller == c) {
        return;
    }
    if (m_controller != nullptr) {
        disconnect(m_controller, &FoxController::previewFrameReady,
                   this, &PreviewItem::onFrameReady);
    }
    m_controller = c;
    if (m_controller != nullptr) {
        connect(m_controller, &FoxController::previewFrameReady,
                this, &PreviewItem::onFrameReady);
    }
    emit controllerChanged();
    update();
}

void PreviewItem::onFrameReady()
{
    update();
}
