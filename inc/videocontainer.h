#ifndef VIDEOCONTAINER_H
#define VIDEOCONTAINER_H

#include <QWidget>
#include <QLabel>

namespace Ui {
class VideoContainer;
}

class VideoContainer : public QWidget
{
    Q_OBJECT

public:
    explicit VideoContainer(QWidget *parent = nullptr);
    void set_preview_image(QImage image);
    ~VideoContainer();

protected:
    // void resizeEvent(QResizeEvent *event) override;

private:
    Ui::VideoContainer *ui;
};

#endif // VIDEOCONTAINER_H
