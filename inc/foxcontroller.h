#ifndef FOXCONTROLLER_H
#define FOXCONTROLLER_H

#include <QObject>
#include <QImage>
#include <QWindow>
#include <QTimer>
#include <QSystemTrayIcon>
#include <QMessageBox>
#include <QJoysticks.h>

#include "HeadPoseDetector.h"
#include "PoseDataSender.h"
#include "poseremapper.h"
#include "uglobalhotkeys.h"

// Backend controller that owns the tracking pipeline and exposes its state and
// all configuration values to the QML UI. Replaces the old QMainWindow-based
// MainWindow as well as the EKFConfig / FilterConfig / SettingConfig widgets.
class FoxController : public QObject
{
    Q_OBJECT

    // ---- Live tracking display ----
    Q_PROPERTY(double x READ x NOTIFY poseChanged)
    Q_PROPERTY(double y READ y NOTIFY poseChanged)
    Q_PROPERTY(double z READ z NOTIFY poseChanged)
    Q_PROPERTY(double yaw READ yaw NOTIFY poseChanged)
    Q_PROPERTY(double pitch READ pitch NOTIFY poseChanged)
    Q_PROPERTY(double roll READ roll NOTIFY poseChanged)
    Q_PROPERTY(double fps READ fps NOTIFY fpsChanged)
    Q_PROPERTY(double timeSec READ timeSec NOTIFY timeChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(bool previewEnabled READ previewEnabled NOTIFY previewEnabledChanged)
    Q_PROPERTY(bool alwaysOnTop READ alwaysOnTop WRITE setAlwaysOnTop NOTIFY alwaysOnTopChanged)
    Q_PROPERTY(int previewWidth READ previewWidth NOTIFY previewFrameReady)
    Q_PROPERTY(int previewHeight READ previewHeight NOTIFY previewFrameReady)

    // ---- EKF noise (log-mapped 0..1 sliders) ----
    Q_PROPERTY(double qNoiseLM READ qNoiseLM WRITE setQNoiseLM NOTIFY settingsChanged)
    Q_PROPERTY(double qNoiseFSA READ qNoiseFSA WRITE setQNoiseFSA NOTIFY settingsChanged)
    Q_PROPERTY(double tNoise READ tNoise WRITE setTNoise NOTIFY settingsChanged)
    Q_PROPERTY(double vNoise READ vNoise WRITE setVNoise NOTIFY settingsChanged)
    Q_PROPERTY(double wNoise READ wNoise WRITE setWNoise NOTIFY settingsChanged)

    // ---- Filter (real-value sliders) ----
    Q_PROPERTY(double rotSmooth READ rotSmooth WRITE setRotSmooth NOTIFY settingsChanged)
    Q_PROPERTY(double rotDeadzone READ rotDeadzone WRITE setRotDeadzone NOTIFY settingsChanged)
    Q_PROPERTY(double transSmooth READ transSmooth WRITE setTransSmooth NOTIFY settingsChanged)
    Q_PROPERTY(double transDeadzone READ transDeadzone WRITE setTransDeadzone NOTIFY settingsChanged)
    Q_PROPERTY(double rotExpoYaw READ rotExpoYaw WRITE setRotExpoYaw NOTIFY settingsChanged)
    Q_PROPERTY(double rotExpoPitch READ rotExpoPitch WRITE setRotExpoPitch NOTIFY settingsChanged)
    Q_PROPERTY(double rotExpoRoll READ rotExpoRoll WRITE setRotExpoRoll NOTIFY settingsChanged)
    Q_PROPERTY(double transExpoX READ transExpoX WRITE setTransExpoX NOTIFY settingsChanged)
    Q_PROPERTY(double transExpoY READ transExpoY WRITE setTransExpoY NOTIFY settingsChanged)
    Q_PROPERTY(double transExpoZ READ transExpoZ WRITE setTransExpoZ NOTIFY settingsChanged)
    Q_PROPERTY(double rotInYaw READ rotInYaw WRITE setRotInYaw NOTIFY settingsChanged)
    Q_PROPERTY(double rotInPitch READ rotInPitch WRITE setRotInPitch NOTIFY settingsChanged)
    Q_PROPERTY(double rotInRoll READ rotInRoll WRITE setRotInRoll NOTIFY settingsChanged)
    Q_PROPERTY(double rotOutYaw READ rotOutYaw WRITE setRotOutYaw NOTIFY settingsChanged)
    Q_PROPERTY(double rotOutPitch READ rotOutPitch WRITE setRotOutPitch NOTIFY settingsChanged)
    Q_PROPERTY(double rotOutRoll READ rotOutRoll WRITE setRotOutRoll NOTIFY settingsChanged)
    Q_PROPERTY(double transInX READ transInX WRITE setTransInX NOTIFY settingsChanged)
    Q_PROPERTY(double transInY READ transInY WRITE setTransInY NOTIFY settingsChanged)
    Q_PROPERTY(double transInZ READ transInZ WRITE setTransInZ NOTIFY settingsChanged)
    Q_PROPERTY(double transOutX READ transOutX WRITE setTransOutX NOTIFY settingsChanged)
    Q_PROPERTY(double transOutY READ transOutY WRITE setTransOutY NOTIFY settingsChanged)
    Q_PROPERTY(double transOutZ READ transOutZ WRITE setTransOutZ NOTIFY settingsChanged)
    Q_PROPERTY(bool useAccela READ useAccela WRITE setUseAccela NOTIFY settingsChanged)
    Q_PROPERTY(bool doubleAccela READ doubleAccela WRITE setDoubleAccela NOTIFY settingsChanged)

    // ---- Setting ----
    Q_PROPERTY(bool useFt READ useFt WRITE setUseFt NOTIFY settingsChanged)
    Q_PROPERTY(bool sendPoseUdp READ sendPoseUdp WRITE setSendPoseUdp NOTIFY settingsChanged)
    Q_PROPERTY(int port READ port WRITE setPort NOTIFY settingsChanged)
    Q_PROPERTY(double detectFps READ detectFps WRITE setDetectFps NOTIFY settingsChanged)
    Q_PROPERTY(int cameraId READ cameraId WRITE setCameraId NOTIFY settingsChanged)
    Q_PROPERTY(int detectDuration READ detectDuration WRITE setDetectDuration NOTIFY settingsChanged)
    Q_PROPERTY(QString udpHost READ udpHost WRITE setUdpHost NOTIFY settingsChanged)
    Q_PROPERTY(int landmarkDetectMethod READ landmarkDetectMethod WRITE setLandmarkDetectMethod NOTIFY settingsChanged)
    Q_PROPERTY(bool enableAutoExpo READ enableAutoExpo WRITE setEnableAutoExpo NOTIFY settingsChanged)
    Q_PROPERTY(double cameraGain READ cameraGain WRITE setCameraGain NOTIFY settingsChanged)
    Q_PROPERTY(double cameraExpo READ cameraExpo WRITE setCameraExpo NOTIFY settingsChanged)
    Q_PROPERTY(double pitchOffsetFsaPnp READ pitchOffsetFsaPnp WRITE setPitchOffsetFsaPnp NOTIFY settingsChanged)

    // ---- Hotkey display ----
    Q_PROPERTY(QString hotkeyJoystick1 READ hotkeyJoystick1 NOTIFY hotkeyChanged)
    Q_PROPERTY(QString hotkeyButton1 READ hotkeyButton1 NOTIFY hotkeyChanged)
    Q_PROPERTY(QString hotkeyJoystick2 READ hotkeyJoystick2 NOTIFY hotkeyChanged)
    Q_PROPERTY(QString hotkeyButton2 READ hotkeyButton2 NOTIFY hotkeyChanged)

public:
    explicit FoxController(QObject *parent = nullptr);
    ~FoxController();

    double x() const { return m_x; }
    double y() const { return m_y; }
    double z() const { return m_z; }
    double yaw() const { return m_yaw; }
    double pitch() const { return m_pitch; }
    double roll() const { return m_roll; }
    double fps() const { return m_fps; }
    double timeSec() const { return m_timeSec; }
    bool running() const { return m_running; }
    bool previewEnabled() const { return m_previewEnabled; }
    bool alwaysOnTop() const { return m_alwaysOnTop; }
    int previewWidth() const { return m_previewImage.width(); }
    int previewHeight() const { return m_previewImage.height(); }

    QImage previewImage() const { return m_previewImage; }
    Q_INVOKABLE void setWindow(QWindow *w) { m_window = w; }

    // EKF noise
    double qNoiseLM() const;       void setQNoiseLM(double v);
    double qNoiseFSA() const;      void setQNoiseFSA(double v);
    double tNoise() const;         void setTNoise(double v);
    double vNoise() const;         void setVNoise(double v);
    double wNoise() const;         void setWNoise(double v);

    // Filter
    double rotSmooth() const;      void setRotSmooth(double v);
    double rotDeadzone() const;    void setRotDeadzone(double v);
    double transSmooth() const;    void setTransSmooth(double v);
    double transDeadzone() const;  void setTransDeadzone(double v);
    double rotExpoYaw() const;     void setRotExpoYaw(double v);
    double rotExpoPitch() const;   void setRotExpoPitch(double v);
    double rotExpoRoll() const;    void setRotExpoRoll(double v);
    double transExpoX() const;     void setTransExpoX(double v);
    double transExpoY() const;     void setTransExpoY(double v);
    double transExpoZ() const;     void setTransExpoZ(double v);
    double rotInYaw() const;       void setRotInYaw(double v);
    double rotInPitch() const;     void setRotInPitch(double v);
    double rotInRoll() const;      void setRotInRoll(double v);
    double rotOutYaw() const;      void setRotOutYaw(double v);
    double rotOutPitch() const;    void setRotOutPitch(double v);
    double rotOutRoll() const;     void setRotOutRoll(double v);
    double transInX() const;       void setTransInX(double v);
    double transInY() const;       void setTransInY(double v);
    double transInZ() const;       void setTransInZ(double v);
    double transOutX() const;      void setTransOutX(double v);
    double transOutY() const;      void setTransOutY(double v);
    double transOutZ() const;      void setTransOutZ(double v);
    bool useAccela() const { return settings->use_accela; }
    void setUseAccela(bool v);
    bool doubleAccela() const { return settings->double_accela; }
    void setDoubleAccela(bool v);

    // Setting
    bool useFt() const { return settings->use_ft; }
    void setUseFt(bool v);
    bool sendPoseUdp() const { return settings->send_posedata_udp; }
    void setSendPoseUdp(bool v);
    int port() const { return settings->port; }
    void setPort(int v);
    double detectFps() const { return settings->fps; }
    void setDetectFps(double v);
    int cameraId() const { return settings->camera_id; }
    void setCameraId(int v);
    int detectDuration() const { return settings->detect_duration; }
    void setDetectDuration(int v);
    QString udpHost() const { return QString::fromStdString(settings->udp_host); }
    void setUdpHost(const QString &v);
    int landmarkDetectMethod() const { return settings->landmark_detect_method; }
    void setLandmarkDetectMethod(int v);
    bool enableAutoExpo() const { return settings->enable_auto_expo; }
    void setEnableAutoExpo(bool v);
    double cameraGain() const { return settings->camera_gain; }
    void setCameraGain(double v);
    double cameraExpo() const { return settings->camera_expo; }
    void setCameraExpo(double v);
    double pitchOffsetFsaPnp() const;
    void setPitchOffsetFsaPnp(double v);

    QString hotkeyJoystick1() const { return QString::fromStdString(settings->hotkey_joystick_names[0]); }
    QString hotkeyButton1() const { return QString::number(settings->hotkey_joystick_buttons[0]); }
    QString hotkeyJoystick2() const { return QString::fromStdString(settings->hotkey_joystick_names[1]); }
    QString hotkeyButton2() const { return QString::number(settings->hotkey_joystick_buttons[1]); }

public slots:
    void start();
    void stop();
    void pause();
    void center();
    void togglePreview();
    void setAlwaysOnTop(bool on);
    void bindHotkey(int index);
    void unbindHotkey(int index);
    void saveConfig();

    void requestClose();
    void minimizeToTray();
    void restoreFromTray();

signals:
    void poseChanged();
    void fpsChanged();
    void timeChanged();
    void runningChanged();
    void previewEnabledChanged();
    void alwaysOnTopChanged();
    void settingsChanged();
    void hotkeyChanged();
    void previewFrameReady();

    // EKF chart data (forwarded from the detector thread).
    void chartPose(double t, double yaw, double pitch, double roll, double x, double y, double z);
    void chartRawPose(double t, double yaw, double pitch, double roll, double x, double y, double z);
    void chartTwist(double t, double wx, double wy, double wz, double vx, double vy, double vz);

private slots:
    void onPose6dData(double t, Pose6DoF pose);
    void onPose6dDataRaw(double t, Pose6DoF pose);
    void onCameraFrame();
    void handleGlobalHotkeys(unsigned int id);
    void iconActivated(QSystemTrayIcon::ActivationReason reason);
    void onChartPose6d(double t, Pose6DoF pose);
    void onChartPose6dRaw(double t, Pose6DoF pose);
    void onChartTwist(double t, Eigen::Vector3d w, Eigen::Vector3d v);
    void onJoystickButton(const QJoystickButtonEvent &event);

private:
    HeadPoseDetector hd;
    PoseDataSender data_sender;
    PoseRemapper remapper;

    double m_x = 0, m_y = 0, m_z = 0;
    double m_yaw = 0, m_pitch = 0, m_roll = 0;
    double m_fps = 0, m_timeSec = 0;
    bool m_running = false;
    bool m_previewEnabled = false;
    bool m_alwaysOnTop = false;

    QImage m_previewImage;

    QTimer *m_timer = nullptr;
    QSystemTrayIcon *m_trayIcon = nullptr;
    QWindow *m_window = nullptr;
    UGlobalHotkeys *m_hotkey = nullptr;
    QMessageBox *m_bindBox = nullptr;
    int m_waitForBind = -1;

    void startCameraPreview();
    void stopCameraPreview();
    void createTrayIcon();
};

#endif // FOXCONTROLLER_H
