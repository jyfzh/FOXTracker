#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <HeadPoseDetector.h>
#include <QTimer>
#include <QSystemTrayIcon>
#include <PoseDataSender.h>
#include "settingconfig.h"
#include "poseremapper.h"
#include "uglobalhotkeys.h"

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

    HeadPoseDetector hd;
    PoseDataSender data_sender;
    PoseRemapper remapper;
    bool is_running = false;

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

protected:
    void closeEvent(QCloseEvent *event) override;
    void changeEvent(QEvent *event) override;

private slots:
    void iconActivated(QSystemTrayIcon::ActivationReason reason);

    void on_pose6d_data(double t, Pose6DoF _pose);
    void on_pose6d_data_raw(double t, Pose6DoF _pose);

    void on_center_keyboard_event();

    void handle_global_hotkeys(unsigned int _id);

    void on_actionstart_triggered();

    void on_actionstop_triggered();

    void on_actionpause_triggered();

    void on_actioncenter_triggered();

    void on_actionalways_on_top_toggled(bool arg1);

    void on_actiontoggle_preview_triggered();

    void on_buttonBox_accepted();

private:
    QTimer* Timer = nullptr;
    bool camera_preview_enabled = false;
    void start_camera_preview();
    void stop_camera_preview();
    Ui::MainWindow *ui;
    void create_tray_icon();

    QSystemTrayIcon* m_tray_icon = nullptr;

    UGlobalHotkeys *hotkeyManager;
};
#endif // MAINWINDOW_H
