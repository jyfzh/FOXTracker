#include "foxcontroller.h"

#include <QCoreApplication>
#include <QTimer>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QMessageBox>
#include <cmath>

namespace {
const double qcov_min = 0.001, qcov_max = 1.0;
const double tcov_min = 0.001, tcov_max = 0.1;
const double wcov_min = 0.1,   wcov_max = 30.0;
const double vcov_min = 0.1,   vcov_max = 20.0;

const double rot_smooth_min = 0.01,  rot_smooth_max = 0.3;
const double rot_deadzone_min = 0.01, rot_deadzone_max = 6.0;
const double trans_smooth_min = 0.01, trans_smooth_max = 0.2;
const double trans_deadzone_min = 0.0, trans_deadzone_max = 0.2;
const double rot_input_min = 10, rot_input_max = 45;
const double rot_output_min = 30, rot_output_max = 180;
const double trans_input_min = 0.10, trans_input_max = 1.0;
const double trans_output_min = 0.30, trans_output_max = 1.0;
const double expo_min = 0.0, expo_max = 1.0;

// log_v / range_v / range_v_inv are provided by inc/utils.h.
inline double log_v_inv(double value, double min, double max) { return log(value / min) / log(max / min); }
}

FoxController::FoxController(QObject *parent)
    : QObject(parent)
{
    m_hotkey = new UGlobalHotkeys();
    m_hotkey->registerHotkey("alt+c", 1);
    connect(m_hotkey, &UGlobalHotkeys::activated,
            this, &FoxController::handleGlobalHotkeys);

    connect(&remapper, &PoseRemapper::send_mapped_posedata,
            this, &FoxController::onPose6dData);
    connect(&remapper, &PoseRemapper::send_mapped_posedata,
            &data_sender, &PoseDataSender::on_pose6d_data);
    connect(&hd, &HeadPoseDetector::on_detect_pose,
            &remapper, &PoseRemapper::on_pose_data, Qt::QueuedConnection);
    connect(&hd, &HeadPoseDetector::on_detect_pose6d_raw,
            this, &FoxController::onPose6dDataRaw);

    // Forward raw detector data to the QML EKF charts.
    connect(&hd, &HeadPoseDetector::on_detect_pose6d,
            this, &FoxController::onChartPose6d, Qt::QueuedConnection);
    connect(&hd, &HeadPoseDetector::on_detect_pose6d_raw,
            this, &FoxController::onChartPose6dRaw, Qt::QueuedConnection);
    connect(&hd, &HeadPoseDetector::on_detect_twist,
            this, &FoxController::onChartTwist, Qt::QueuedConnection);

    // Joystick hotkey binding / triggering.
    QJoysticks::getInstance()->setVirtualJoystickEnabled(true);
    connect(QJoysticks::getInstance(), &QJoysticks::buttonEvent,
            this, &FoxController::onJoystickButton);

    emit hd.start();
    remapper.reset_center();
    startCameraPreview();
    m_running = true;
    emit runningChanged();
}

FoxController::~FoxController()
{
    delete m_trayIcon;
    delete m_hotkey;
    delete m_bindBox;
}

// ---------------- live tracking ----------------

void FoxController::onPose6dData(double t, Pose6DoF pose)
{
    m_x = pose.second.x() * 100;
    m_y = pose.second.y() * 100;
    m_z = pose.second.z() * 100;
    m_yaw = pose.first.x();
    m_pitch = pose.first.y();
    m_roll = pose.first.z();
    emit poseChanged();

    m_timeSec = t;
    emit timeChanged();
}

void FoxController::onPose6dDataRaw(double t, Pose6DoF)
{
    static double t_last = 0;
    static double fps = 0;
    if (t_last != 0) {
        fps = 1 / (t - t_last) * 0.05 + fps * 0.95;
    }
    t_last = t;
    m_fps = fps;
    emit fpsChanged();
}

void FoxController::startCameraPreview()
{
    if (m_timer == nullptr) {
        m_timer = new QTimer(this);
        connect(m_timer, &QTimer::timeout, this, &FoxController::onCameraFrame);
    }
    settings->enable_preview = true;
    m_timer->start(30);
    m_previewEnabled = true;
    emit previewEnabledChanged();
}

void FoxController::stopCameraPreview()
{
    settings->enable_preview = false;
    m_previewEnabled = false;
    emit previewEnabledChanged();
    if (m_timer != nullptr) {
        m_timer->stop();
    }
}

void FoxController::onCameraFrame()
{
    cv::Mat img = hd.get_preview_image();
    if (img.empty()) {
        return;
    }
    m_previewImage = QImage(img.data, img.cols, img.rows,
                            (int)img.step, QImage::Format_BGR888).copy();
    emit previewFrameReady();
}

// ---------------- transport / window control ----------------

void FoxController::start()
{
    if (!m_running) {
        emit hd.start();
        remapper.reset_center();
        startCameraPreview();
        m_running = true;
        emit runningChanged();
    }
}

void FoxController::stop()
{
    if (m_running) {
        emit hd.stop();
        stopCameraPreview();
        m_running = false;
        emit runningChanged();
    }
}

void FoxController::pause()
{
    hd.pause();
    if (m_timer != nullptr) {
        if (m_timer->isActive()) {
            m_timer->stop();
        } else {
            m_timer->start();
        }
    }
}

void FoxController::center()
{
    remapper.reset_center();
}

void FoxController::togglePreview()
{
    if (m_previewEnabled) {
        stopCameraPreview();
    } else {
        startCameraPreview();
    }
}

void FoxController::setAlwaysOnTop(bool on)
{
    if (m_alwaysOnTop == on) {
        return;
    }
    m_alwaysOnTop = on;
    if (m_window != nullptr) {
        Qt::WindowFlags flags = m_window->flags();
        if (on) {
            flags |= Qt::WindowStaysOnTopHint;
            flags |= Qt::FramelessWindowHint;
        } else {
            flags &= ~Qt::WindowStaysOnTopHint;
            flags &= ~Qt::FramelessWindowHint;
        }
        m_window->setFlags(flags);
        m_window->show();
    }
    emit alwaysOnTopChanged();
}

void FoxController::requestClose()
{
    emit hd.stop();
    stopCameraPreview();
    m_running = false;
    emit runningChanged();
    QCoreApplication::quit();
}

void FoxController::minimizeToTray()
{
    stopCameraPreview();
    if (m_window != nullptr) {
        m_window->hide();
    }
    createTrayIcon();
}

void FoxController::restoreFromTray()
{
    if (m_window != nullptr) {
        m_window->showNormal();
        m_window->raise();
        m_window->requestActivate();
    }
    startCameraPreview();
}

void FoxController::handleGlobalHotkeys(unsigned int id)
{
    if (id == 1) {
        center();
    }
}

void FoxController::createTrayIcon()
{
    if (m_trayIcon == nullptr) {
        m_trayIcon = new QSystemTrayIcon(QIcon(":/icons/icon.png"), this);

        QAction *quit_action = new QAction("Exit", m_trayIcon);
        connect(quit_action, &QAction::triggered, this, &FoxController::requestClose);

        QAction *show_action = new QAction("Show", m_trayIcon);
        connect(show_action, &QAction::triggered, this, &FoxController::restoreFromTray);

        connect(m_trayIcon, SIGNAL(activated(QSystemTrayIcon::ActivationReason)),
                this, SLOT(iconActivated(QSystemTrayIcon::ActivationReason)));

        QMenu *tray_icon_menu = new QMenu;
        tray_icon_menu->addAction(show_action);
        tray_icon_menu->addAction(quit_action);

        m_trayIcon->setContextMenu(tray_icon_menu);
        m_trayIcon->show();
    }
}

void FoxController::iconActivated(QSystemTrayIcon::ActivationReason reason)
{
    switch (reason) {
    case QSystemTrayIcon::Trigger:
    case QSystemTrayIcon::DoubleClick:
        restoreFromTray();
        break;
    default:
        break;
    }
}

// ---------------- EKF charts ----------------

void FoxController::onChartPose6d(double t, Pose6DoF pose)
{
    if (t - m_lastChartPose < kChartMinInterval)
        return;
    m_lastChartPose = t;
    emit chartPose(t, pose.first.x(), pose.first.y(), pose.first.z(),
                   pose.second.x(), pose.second.y(), pose.second.z());
}

void FoxController::onChartPose6dRaw(double t, Pose6DoF pose)
{
    if (t - m_lastChartRaw < kChartMinInterval)
        return;
    m_lastChartRaw = t;
    emit chartRawPose(t, pose.first.x(), pose.first.y(), pose.first.z(),
                      pose.second.x(), pose.second.y(), pose.second.z());
}

void FoxController::onChartTwist(double t, Eigen::Vector3d w, Eigen::Vector3d v)
{
    if (t - m_lastChartTwist < kChartMinInterval)
        return;
    m_lastChartTwist = t;
    emit chartTwist(t, w.x(), w.y(), w.z(), v.x(), v.y(), v.z());
}

// ---------------- joystick hotkeys ----------------

void FoxController::onJoystickButton(const QJoystickButtonEvent &event)
{
    std::string joyname = event.joystick->name.toUtf8().constData();
    int btn_id = event.button;
    if (event.pressed && m_waitForBind >= 0) {
        settings->hotkey_joystick_names[m_waitForBind] = joyname;
        settings->hotkey_joystick_buttons[m_waitForBind] = btn_id;
        if (m_bindBox != nullptr) {
            m_bindBox->done(0);
        }
        m_waitForBind = -1;
        emit hotkeyChanged();
        return;
    }
    if (event.pressed) {
        for (size_t i = 0; i < settings->hotkey_joystick_names.size(); i++) {
            if (settings->hotkey_joystick_names[i] == joyname &&
                settings->hotkey_joystick_buttons[i] == btn_id) {
                if (i == 0) {
                    remapper.reset_center();
                } else if (i == 1) {
                    hd.pause();
                }
            }
        }
    }
}

void FoxController::bindHotkey(int index)
{
    delete m_bindBox;
    m_bindBox = new QMessageBox();
    m_bindBox->setText(index == 0 ? "Press any key to bind re-center key"
                                  : "Press any key to bind pause key");
    m_bindBox->setStandardButtons(QMessageBox::Cancel);
    m_waitForBind = index;
    m_bindBox->exec();
    delete m_bindBox;
    m_bindBox = nullptr;
    m_waitForBind = -1;
}

void FoxController::unbindHotkey(int index)
{
    settings->hotkey_joystick_names[index] = "";
    settings->hotkey_joystick_buttons[index] = 0;
    emit hotkeyChanged();
}

void FoxController::saveConfig()
{
    if (settings->udp_host != udpHost().toStdString() || settings->port != port()) {
        settings->udp_host = udpHost().toStdString();
        settings->set_value<std::string>("udp_host", settings->udp_host);
        settings->port = port();
        settings->set_value<int>("port", settings->port);
    }
    if (cameraId() != settings->camera_id || detectFps() != settings->fps) {
        settings->camera_id = cameraId();
        settings->set_value<int>("camera_id", settings->camera_id);
        settings->fps = detectFps();
        settings->set_value<double>("fps", settings->fps);
        hd.reset();
    }
    settings->detect_duration = detectDuration();
    settings->set_value<int>("detect_duration", settings->detect_duration);
    settings->write_to_file();
}

// ---------------- EKF noise (log-mapped) ----------------

double FoxController::qNoiseLM() const { return log_v_inv(settings->cov_Q_lm, qcov_min, qcov_max); }
void FoxController::setQNoiseLM(double v) { settings->cov_Q_lm = log_v(v, qcov_min, qcov_max); settings->set_value<double>("cov_Q_lm", settings->cov_Q_lm); emit settingsChanged(); }

double FoxController::qNoiseFSA() const { return log_v_inv(settings->cov_Q_fsa, qcov_min, qcov_max); }
void FoxController::setQNoiseFSA(double v) { settings->cov_Q_fsa = log_v(v, qcov_min, qcov_max); settings->set_value<double>("cov_Q_fsa", settings->cov_Q_fsa); emit settingsChanged(); }

double FoxController::tNoise() const { return log_v_inv(settings->cov_T, tcov_min, tcov_max); }
void FoxController::setTNoise(double v) { settings->cov_T = log_v(v, tcov_min, tcov_max); settings->set_value<double>("cov_T", settings->cov_T); emit settingsChanged(); }

double FoxController::vNoise() const { return log_v_inv(settings->cov_V, vcov_min, vcov_max); }
void FoxController::setVNoise(double v) { settings->cov_V = log_v(v, vcov_min, vcov_max); settings->set_value<double>("cov_V", settings->cov_V); emit settingsChanged(); }

double FoxController::wNoise() const { return log_v_inv(settings->cov_W, wcov_min, wcov_max); }
void FoxController::setWNoise(double v) { settings->cov_W = log_v(v, wcov_min, wcov_max); settings->set_value<double>("cov_W", settings->cov_W); emit settingsChanged(); }

// ---------------- Filter (real-value) ----------------

double FoxController::rotSmooth() const { return settings->accela_s.rot_smoothing; }
void FoxController::setRotSmooth(double v) { settings->accela_s.rot_smoothing = v; settings->set_value<double>("accela_rot_smoothing", v); emit settingsChanged(); }

double FoxController::rotDeadzone() const { return settings->accela_s.rot_deadzone; }
void FoxController::setRotDeadzone(double v) { settings->accela_s.rot_deadzone = v; settings->set_value<double>("accela_rot_deadzone", v); emit settingsChanged(); }

double FoxController::transSmooth() const { return settings->accela_s.pos_smoothing; }
void FoxController::setTransSmooth(double v) { settings->accela_s.pos_smoothing = v; settings->set_value<double>("accela_pos_smoothing", v); emit settingsChanged(); }

double FoxController::transDeadzone() const { return settings->accela_s.pos_deadzone; }
void FoxController::setTransDeadzone(double v) { settings->accela_s.pos_deadzone = v; settings->set_value<double>("accela_pos_deadzone", v); emit settingsChanged(); }

double FoxController::rotExpoYaw() const { return settings->expo_eul(0); }
void FoxController::setRotExpoYaw(double v) { settings->expo_eul(0) = v; settings->set_value<double>("expo_eul_yaw", v); emit settingsChanged(); }
double FoxController::rotExpoPitch() const { return settings->expo_eul(1); }
void FoxController::setRotExpoPitch(double v) { settings->expo_eul(1) = v; settings->set_value<double>("expo_eul_pitch", v); emit settingsChanged(); }
double FoxController::rotExpoRoll() const { return settings->expo_eul(2); }
void FoxController::setRotExpoRoll(double v) { settings->expo_eul(2) = v; settings->set_value<double>("expo_eul_roll", v); emit settingsChanged(); }

double FoxController::transExpoX() const { return settings->expo_trans.x(); }
void FoxController::setTransExpoX(double v) { settings->expo_trans.x() = v; settings->set_value<double>("expo_trans_x", v); emit settingsChanged(); }
double FoxController::transExpoY() const { return settings->expo_trans.y(); }
void FoxController::setTransExpoY(double v) { settings->expo_trans.y() = v; settings->set_value<double>("expo_trans_y", v); emit settingsChanged(); }
double FoxController::transExpoZ() const { return settings->expo_trans.z(); }
void FoxController::setTransExpoZ(double v) { settings->expo_trans.z() = v; settings->set_value<double>("expo_trans_z", v); emit settingsChanged(); }

double FoxController::rotInYaw() const { return settings->inp_bound_eul(0); }
void FoxController::setRotInYaw(double v) { settings->inp_bound_eul(0) = v; settings->set_value<double>("inp_bound_yaw", v); emit settingsChanged(); }
double FoxController::rotInPitch() const { return settings->inp_bound_eul(1); }
void FoxController::setRotInPitch(double v) { settings->inp_bound_eul(1) = v; settings->set_value<double>("inp_bound_pitch", v); emit settingsChanged(); }
double FoxController::rotInRoll() const { return settings->inp_bound_eul(2); }
void FoxController::setRotInRoll(double v) { settings->inp_bound_eul(2) = v; settings->set_value<double>("inp_bound_roll", v); emit settingsChanged(); }

double FoxController::rotOutYaw() const { return settings->out_bound_eul(0); }
void FoxController::setRotOutYaw(double v) { settings->out_bound_eul(0) = v; settings->set_value<double>("out_bound_yaw", v); emit settingsChanged(); }
double FoxController::rotOutPitch() const { return settings->out_bound_eul(1); }
void FoxController::setRotOutPitch(double v) { settings->out_bound_eul(1) = v; settings->set_value<double>("out_bound_pitch", v); emit settingsChanged(); }
double FoxController::rotOutRoll() const { return settings->out_bound_eul(2); }
void FoxController::setRotOutRoll(double v) { settings->out_bound_eul(2) = v; settings->set_value<double>("out_bound_roll", v); emit settingsChanged(); }

double FoxController::transInX() const { return settings->inp_bound_trans.x(); }
void FoxController::setTransInX(double v) { settings->inp_bound_trans.x() = v; settings->set_value<double>("inp_bound_x", v); emit settingsChanged(); }
double FoxController::transInY() const { return settings->inp_bound_trans.y(); }
void FoxController::setTransInY(double v) { settings->inp_bound_trans.y() = v; settings->set_value<double>("inp_bound_y", v); emit settingsChanged(); }
double FoxController::transInZ() const { return settings->inp_bound_trans.z(); }
void FoxController::setTransInZ(double v) { settings->inp_bound_trans.z() = v; settings->set_value<double>("inp_bound_z", v); emit settingsChanged(); }

double FoxController::transOutX() const { return settings->out_bound_trans.x(); }
void FoxController::setTransOutX(double v) { settings->out_bound_trans.x() = v; settings->set_value<double>("out_bound_x", v); emit settingsChanged(); }
double FoxController::transOutY() const { return settings->out_bound_trans.y(); }
void FoxController::setTransOutY(double v) { settings->out_bound_trans.y() = v; settings->set_value<double>("out_bound_y", v); emit settingsChanged(); }
double FoxController::transOutZ() const { return settings->out_bound_trans.z(); }
void FoxController::setTransOutZ(double v) { settings->out_bound_trans.z() = v; settings->set_value<double>("out_bound_z", v); emit settingsChanged(); }

void FoxController::setUseAccela(bool v) { settings->use_accela = v; settings->set_value<bool>("use_accela", v); emit settingsChanged(); }
void FoxController::setDoubleAccela(bool v) { settings->double_accela = v; settings->set_value<bool>("double_accela", v); emit settingsChanged(); }

// ---------------- Setting ----------------

void FoxController::setUseFt(bool v) { settings->use_ft = settings->use_npclient = v; settings->set_value<bool>("use_ft", v); settings->set_value<bool>("use_npclient", v); emit settingsChanged(); }
void FoxController::setSendPoseUdp(bool v) { settings->send_posedata_udp = v; settings->set_value<bool>("send_posedata_udp", v); emit settingsChanged(); }
void FoxController::setPort(int v) { settings->port = v; settings->set_value<int>("port", v); emit settingsChanged(); }
void FoxController::setDetectFps(double v) { settings->fps = v; settings->set_value<double>("fps", v); emit settingsChanged(); }
void FoxController::setCameraId(int v) { settings->camera_id = v; settings->set_value<int>("camera_id", v); emit settingsChanged(); }
void FoxController::setDetectDuration(int v) { settings->detect_duration = v; settings->set_value<int>("detect_duration", v); emit settingsChanged(); }
void FoxController::setUdpHost(const QString &v) { settings->udp_host = v.toStdString(); settings->set_value<std::string>("udp_host", settings->udp_host); emit settingsChanged(); }
void FoxController::setLandmarkDetectMethod(int v) { settings->set_landmark_level(v); settings->set_value<int>("landmark_detect_method", v); emit settingsChanged(); }
void FoxController::setEnableAutoExpo(bool v) { settings->enable_auto_expo = v; hd.set_auto_expo(v); settings->set_value<bool>("enable_auto_expo", v); emit settingsChanged(); }
void FoxController::setCameraGain(double v) { settings->camera_gain = v; hd.set_gain(v); settings->set_value<double>("camera_gain", v); emit settingsChanged(); }
void FoxController::setCameraExpo(double v) { settings->camera_expo = v; hd.set_expo(v); settings->set_value<double>("camera_expo", v); emit settingsChanged(); }

double FoxController::pitchOffsetFsaPnp() const
{
    return (settings->pitch_offset_fsa_pnp * RAD2DEG) / 20.0;
}
void FoxController::setPitchOffsetFsaPnp(double v)
{
    float offset = float(v * 20.0) * float(DEG2RAD);
    settings->pitch_offset_fsa_pnp = offset;
    settings->set_value("pitch_offset_fsa_pnp", offset);
    emit settingsChanged();
}
