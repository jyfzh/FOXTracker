#include "videocontainer.h"
#include "ui_videocontainer.h"

VideoContainer::VideoContainer(QWidget *parent)
    : QWidget(parent)
    , ui(new Ui::VideoContainer)
{
    ui->setupUi(this);

    QImage imdisplay;
    ui->preview->setPixmap(QPixmap::fromImage(imdisplay));
}

void VideoContainer::set_preview_image(QImage image) {
    ui->preview->setPixmap(QPixmap::fromImage(image));
}

VideoContainer::~VideoContainer()
{
    delete ui;
}
