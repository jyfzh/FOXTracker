#include "FlightAgxSettings.h"
#include <QFile>
#include <QFileInfo>
#include <iostream>
#include <fstream>

void FlightAgxSettings::load_from_config_yaml() {
    const QString config_path = QString::fromStdString(cfg_name);
    const QString template_path = QString::fromStdString(config_template_name);

    try {
        // A clean Linux build may not have a user config yet. Seed it from the
        // deployed template when possible, but still load the template if the
        // executable directory is read-only.
        if (!QFile::exists(config_path) && QFile::exists(template_path)) {
            const QFileInfo config_info(config_path);
            if (!QDir().mkpath(config_info.absolutePath()) ||
                !QFile::copy(template_path, config_path)) {
                qWarning() << "Could not seed config at" << config_path;
            }
        }

        if (QFile::exists(config_path)) {
            qDebug() << "Read config at" << config_path;
            config = YAML::LoadFile(cfg_name);
        } else if (QFile::exists(template_path)) {
            qWarning() << "Config not found at" << config_path
                       << "; loading template";
            config = YAML::LoadFile(config_template_name);
        } else {
            qWarning() << "Neither config nor template exists at" << config_path;
            config = YAML::Node(YAML::NodeType::Map);
            return;
        }

        // UI theme: read right after loading, with its own guard, so a
        // failure in any of the optional keys below cannot lose it.
        try {
            if (config["ui_theme"])
                ui_theme = config["ui_theme"].as<std::string>();
        } catch (const YAML::Exception &e) {
            qWarning() << "Failed to read ui_theme:" << e.what();
        }
        detect_duration = config["detect_duration"].as<double>();
        camera_id = config["camera_id"].as<int>();
        enable_multithread_detect = config["enable_multithread_detect"].as<bool>();
        retrack_queue_size = config["retrack_queue_size"].as<int>();
        fps = config["fps"].as<double>();
        send_posedata_udp = config["send_posedata_udp"].as<bool>();
        port = config["port"].as<int>();
        udp_host = config["udp_host"].as<std::string>();
        qDebug() << "Will send to" << udp_host.c_str();
        use_ft = config["use_ft"].as<bool>();
        use_npclient = config["use_npclient"].as<bool>();
        cov_Q_fsa = config["cov_Q_fsa"].as<double>();
        cov_Q_lm = config["cov_Q_lm"].as<double>();
        cov_T = config["cov_T"].as<double>();

        cov_V = config["cov_V"].as<double>();
        cov_W = config["cov_W"].as<double>();

        set_landmark_level(config["landmark_detect_method"].as<int>());

        ekf_predict_dt = config["ekf_predict_dt"].as<double>();
        use_ekf = config["use_ekf"].as<bool>();
        disp_duration = config["disp_duration"].as<double>();
        disp_max_series_size = config["disp_max_series_size"].as<int>();
        fsa_pnp_mixture_rate = config["fsa_pnp_mixture_rate"].as<double>();

        hotkey_joystick_names.resize(2);
        hotkey_joystick_buttons.resize(2);

        hotkey_joystick_names[0] = config["hotkey_joystick_name0"].as<std::string>();
        hotkey_joystick_buttons[0] = config["hotkey_joystick_button0"].as<int>();

        hotkey_joystick_names[1] = config["hotkey_joystick_name1"].as<std::string>();
        hotkey_joystick_buttons[1] = config["hotkey_joystick_button1"].as<int>();

        pitch_offset_fsa_pnp = config["pitch_offset_fsa_pnp"].as<float>();

        cervical_face_model_x = config["cervical_face_model_x"].as<float>();
        cervical_face_model_y = config["cervical_face_model_y"].as<float>();
        cervical_face_model = config["cervical_face_model"].as<float>();

        enable_gpu = config["enable_gpu"].as<bool>();

        enable_auto_expo = config["enable_auto_expo"].as<bool>();
        camera_expo = config["camera_expo"].as<double>();
        camera_gain = config["camera_gain"].as<double>();

        enable_face_spd_est = config["enable_face_spd_est"].as<bool>();
        //Curve mapping
        inp_bound_trans.x() = config["inp_bound_x"].as<double>();
        inp_bound_trans.y() = config["inp_bound_y"].as<double>();
        inp_bound_trans.z() = config["inp_bound_z"].as<double>();

        inp_bound_eul(2) = config["inp_bound_roll"].as<double>();
        inp_bound_eul(1) = config["inp_bound_pitch"].as<double>();
        inp_bound_eul(0) = config["inp_bound_yaw"].as<double>();

        out_bound_trans.x() = config["out_bound_x"].as<double>();
        out_bound_trans.y() = config["out_bound_y"].as<double>();
        out_bound_trans.z() = config["out_bound_z"].as<double>();

        out_bound_eul(2) = config["out_bound_roll"].as<double>();
        out_bound_eul(1) = config["out_bound_pitch"].as<double>();
        out_bound_eul(0) = config["out_bound_yaw"].as<double>();

        expo_trans.x() = config["expo_trans_x"].as<double>();
        expo_trans.y() = config["expo_trans_y"].as<double>();
        expo_trans.z() = config["expo_trans_z"].as<double>();

        expo_eul(0) = config["expo_eul_yaw"].as<double>();
        expo_eul(1) = config["expo_eul_pitch"].as<double>();
        expo_eul(2) = config["expo_eul_roll"].as<double>();

        use_accela = config["use_accela"].as<bool>();
        double_accela = config["double_accela"].as<bool>();
        accela_s.rot_smoothing = config["accela_rot_smoothing"].as<double>();
        accela_s.rot_deadzone = config["accela_rot_deadzone"].as<double>();

        accela_s.pos_smoothing = config["accela_pos_smoothing"].as<double>();
        accela_s.pos_deadzone = config["accela_pos_deadzone"].as<double>();
    } catch (const YAML::Exception &e) {
        qWarning() << "Failed to load config at" << cfg_name.c_str() << ":" << e.what();
        qWarning() << "Continuing with default settings.";
        return;
    }
}


void FlightAgxSettings::write_to_file() {
    config["ui_theme"] = ui_theme;

    // ---- Persist EKF noise (mirrors load_from_config_yaml) ----
    config["cov_Q_lm"] = cov_Q_lm;
    config["cov_Q_fsa"] = cov_Q_fsa;
    config["cov_T"] = cov_T;
    config["cov_V"] = cov_V;
    config["cov_W"] = cov_W;

    // ---- Persist Filter / remapper curves + Accela ----
    config["inp_bound_x"] = inp_bound_trans.x();
    config["inp_bound_y"] = inp_bound_trans.y();
    config["inp_bound_z"] = inp_bound_trans.z();
    config["inp_bound_yaw"] = inp_bound_eul(0);
    config["inp_bound_pitch"] = inp_bound_eul(1);
    config["inp_bound_roll"] = inp_bound_eul(2);
    config["out_bound_x"] = out_bound_trans.x();
    config["out_bound_y"] = out_bound_trans.y();
    config["out_bound_z"] = out_bound_trans.z();
    config["out_bound_yaw"] = out_bound_eul(0);
    config["out_bound_pitch"] = out_bound_eul(1);
    config["out_bound_roll"] = out_bound_eul(2);
    config["expo_trans_x"] = expo_trans.x();
    config["expo_trans_y"] = expo_trans.y();
    config["expo_trans_z"] = expo_trans.z();
    config["expo_eul_yaw"] = expo_eul(0);
    config["expo_eul_pitch"] = expo_eul(1);
    config["expo_eul_roll"] = expo_eul(2);
    config["use_accela"] = use_accela;
    config["double_accela"] = double_accela;
    config["accela_rot_smoothing"] = accela_s.rot_smoothing;
    config["accela_rot_deadzone"] = accela_s.rot_deadzone;
    config["accela_pos_smoothing"] = accela_s.pos_smoothing;
    config["accela_pos_deadzone"] = accela_s.pos_deadzone;

    config["hotkey_joystick_name0"] = hotkey_joystick_names[0];
    config["hotkey_joystick_button0"] = hotkey_joystick_buttons[0];

    config["hotkey_joystick_name1"] = hotkey_joystick_names[1];
    config["hotkey_joystick_button1"] = hotkey_joystick_buttons[1];

    const QFileInfo config_info(QString::fromStdString(cfg_name));
    if (!QDir().mkpath(config_info.absolutePath()) &&
        !QDir(config_info.absolutePath()).exists()) {
        qWarning() << "Failed to create config directory"
                   << config_info.absolutePath();
        return;
    }

    std::ofstream fout(cfg_name.c_str());
    if (!fout.is_open()) {
        qWarning() << "Failed to open config for writing at" << cfg_name.c_str()
                   << "(check file permissions)";
        return;
    }
    fout << config;
    fout.close();
    qDebug() << "Succesful write config to file";
}
