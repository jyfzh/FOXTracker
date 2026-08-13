#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <FlightAgxSettings.h>
#include <QAction>
#include <QMenu>
#include <QDebug>
#include <QScreen>

#include "settingconfig.h"

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    this->setWindowTitle("FOXTracker");

    status_fps_label = new QLabel("FPS: 0", this);
    status_fps_label->setFixedWidth(120);
    statusBar()->addPermanentWidget(status_fps_label);
    status_time_label = new QLabel("Time: 0", this);
    status_time_label->setFixedWidth(120);
    statusBar()->addPermanentWidget(status_time_label);

    setWindowFlags(windowFlags() | Qt::WindowSystemMenuHint);

    emit hd.start();
    this->remapper.reset_center();
    this->start_camera_preview();
    is_running = true;

    connect(&remapper, &PoseRemapper::send_mapped_posedata, this, &MainWindow::on_pose6d_data);
    connect(&remapper, &PoseRemapper::send_mapped_posedata, &data_sender, &PoseDataSender::on_pose6d_data);
    connect(&hd, &HeadPoseDetector::on_detect_pose, &remapper, &PoseRemapper::on_pose_data, Qt::QueuedConnection);
    connect(&hd, &HeadPoseDetector::on_detect_pose6d_raw, this, &MainWindow::on_pose6d_data_raw);

    // connect(&hd, &HeadPoseDetector::on_detect_pose6d, config_menu->ekf_config_menu(),
    //         &EKFConfig::on_detect_pose6d);
    // connect(&hd, &HeadPoseDetector::on_detect_twist, config_menu->ekf_config_menu(),
    //         &EKFConfig::on_detect_twist);

    hotkeyManager = new UGlobalHotkeys();
    hotkeyManager->registerHotkey("alt+c", 1);

    connect(hotkeyManager, &UGlobalHotkeys::activated, this, &MainWindow::handle_global_hotkeys);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::closeEvent(QCloseEvent *event)
{
    emit hd.stop();
    this->stop_camera_preview();
    is_running = false;

    event->accept();
}


void MainWindow::changeEvent(QEvent *event)
{
    if(event->type() == QEvent::WindowStateChange)
    {
        if(windowState() == Qt::WindowMinimized) {
            this->stop_camera_preview();
            hide();
            create_tray_icon();
        }
    }

    QMainWindow::changeEvent(event);
}

void MainWindow::handle_global_hotkeys(unsigned int _id) {
    if (_id == 1) {
        this->on_center_keyboard_event();
    }
}

void MainWindow::create_tray_icon() {
    if (m_tray_icon == nullptr) {
        m_tray_icon = new QSystemTrayIcon(QIcon(":/icons/icon.png"), this);

        QAction *quit_action = new QAction( "Exit", m_tray_icon );
        connect( quit_action, &QAction::triggered, this, [](){
            QCoreApplication::quit();
        } );

        QAction *hide_action = new QAction( "Show", m_tray_icon );
        connect( hide_action, &QAction::triggered, this, [this](){
            this->show();
            this->showNormal();
        } );

        connect(m_tray_icon,SIGNAL(activated(QSystemTrayIcon::ActivationReason)),
                this ,SLOT(iconActivated(QSystemTrayIcon::ActivationReason)));

        QMenu *tray_icon_menu = new QMenu;
        tray_icon_menu->addAction( hide_action );
        tray_icon_menu->addAction( quit_action );

        m_tray_icon->setContextMenu( tray_icon_menu );
        m_tray_icon->show();
    }
}

void MainWindow::iconActivated(QSystemTrayIcon::ActivationReason reason) {
    switch (reason) {
       case QSystemTrayIcon::Trigger:
       case QSystemTrayIcon::DoubleClick:
            QTimer::singleShot(0, this, [this](){
                this->showNormal();
                this->raise();
                this->activateWindow();
                show();
            });
            start_camera_preview();
       default:
        break;
    }
}

void MainWindow::on_pose6d_data(double t, Pose6DoF _pose) {
    ui->time_disp->display(t);
    ui->x_disp->display(_pose.second.x() * 100);
    ui->y_disp->display(_pose.second.y() * 100);
    ui->z_disp->display(_pose.second.z() * 100);
    ui->yaw_disp->display(_pose.first.x());
    ui->pitch_disp->display(_pose.first.y());
    ui->roll_disp->display(_pose.first.z());

    status_time_label->setText("Time: " + QString::number(t));
}

void MainWindow::on_pose6d_data_raw(double t, Pose6DoF _pose) {
    static double t_last = 0;
    static double fps = 0;
    if (t_last != 0) {
        fps = 1/(t - t_last)*0.05 + fps*0.95;
    }
    t_last = t;
    ui->fps_disp->display(fps);
    status_fps_label->setText("FPS: " + QString::number(fps));
}

void MainWindow::start_camera_preview() {
    if (Timer == nullptr) {
        Timer = new QTimer(this);
        connect(Timer, &QTimer::timeout, this, [this](){
            cv::Mat img = hd.get_preview_image();
            if (img.empty()) {
                return;
            }
            QImage imdisplay((uchar*)img.data, img.cols, img.rows, img.step, QImage::Format_BGR888);
            ui->preview_camera->setPixmap(QPixmap::fromImage(imdisplay));
        });
    }
    settings->enable_preview = true;
    Timer->start(30);
    camera_preview_enabled = true;
}

void MainWindow::stop_camera_preview() {
    settings->enable_preview = false;
    camera_preview_enabled = false;
    if (Timer != nullptr) {
        Timer->stop();
    }
}

void MainWindow::on_center_keyboard_event() {
//    hd.reset_detect();
    remapper.reset_center();
}

void MainWindow::on_actionstart_triggered()
{
    if(!is_running) {
        emit hd.start();
        this->remapper.reset_center();
        this->start_camera_preview();
        is_running = true;
    }
}


void MainWindow::on_actionstop_triggered()
{
    if(is_running) {
        emit hd.stop();
        this->stop_camera_preview();
        is_running = false;
    }
}


void MainWindow::on_actionpause_triggered()
{
    hd.pause();
    if (Timer != nullptr) {
        if (Timer->isActive()) {
            Timer->stop();
        } else {
            Timer->start();
        }
    }
}

void MainWindow::on_actioncenter_triggered()
{
    on_center_keyboard_event();
}


void MainWindow::on_actionalways_on_top_toggled(bool arg1)
{
    Qt::WindowFlags flags = this->windowFlags();

    if (arg1) {
        flags |= Qt::WindowStaysOnTopHint;
        flags |= Qt::FramelessWindowHint;
    } else {
        flags &= ~Qt::WindowStaysOnTopHint;
        flags &= ~Qt::FramelessWindowHint;
    }

    this->setWindowFlags(flags);
    this->show();
}

void MainWindow::on_actiontoggle_preview_triggered()
{
    if (camera_preview_enabled) {
        this->stop_camera_preview();
    } else {
        this->start_camera_preview();
    }
}

void MainWindow::on_buttonBox_accepted()
{

}

