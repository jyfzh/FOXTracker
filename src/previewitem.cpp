#include "previewitem.h"
#include <QApplication>
#include <QPalette>
#include <QPainter>

PreviewItem::PreviewItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setRenderTarget(QQuickPaintedItem::FramebufferObject);
}

void PreviewItem::paint(QPainter *painter)
{
    QRectF rect = boundingRect();
    // Viewport background unified with Theme.viewportBg — keep the preview
    // scrim consistent with the QML dark/light palette instead of a fixed
    // dark fill. Detect dark mode via the application palette's WindowText
    // lightness (mirrors ThemeManager's dark flag without a direct dependency).
    const bool isDark = qApp->palette().color(QPalette::WindowText).lightness() > 128;
    const QColor viewportBg = isDark ? QColor(0x10, 0x11, 0x14) : QColor(0xE9, 0xEB, 0xEF);
    painter->fillRect(rect, viewportBg);
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
