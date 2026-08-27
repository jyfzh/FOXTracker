cmake_minimum_required(VERSION 3.24)
project(FOXTracker
    VERSION 1.0.0
    DESCRIPTION "Face tracking application for flight simulators"
    LANGUAGES CXX C
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(FOXTRACKER_ENABLE_PS3EYE "Build PS3 Eye camera support when the submodule is available" ON)

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

if(MSVC)
    add_compile_definitions(
        _USE_MATH_DEFINES
        _MBCS
        CERES_MSVC_USE_UNDERSCORE_PREFIXED_BESSEL_FUNCTIONS
        GOOGLE_GLOG_DLL_DECL=
        NOMINMAX
    )
    add_compile_options(/W3 /utf-8)
endif()

include("${PROJECT_SOURCE_DIR}/cmake/Dependencies.cmake")

add_subdirectory(lib)

set(FOXTRACKER_SOURCES
    src/FaceDetectors.cpp
    src/FlightAgxSettings.cpp
    src/FSANet.cpp
    src/HeadPoseDetector.cpp
    src/KalmanFilter.cpp
    src/main.cpp
    src/foxcontroller.cpp
    src/previewitem.cpp
    src/PoseDataSender.cpp
    src/poseremapper.cpp
    src/LogManager.cpp
    src/ThemeManager.cpp
    src/stereo_bundle_adjustment.cpp
)

add_executable(FOXTracker WIN32
    ${FOXTRACKER_SOURCES}
    "${PROJECT_SOURCE_DIR}/assets/main.qrc"
    "${PROJECT_SOURCE_DIR}/inc/HeadPoseDetector.h"
    "${PROJECT_SOURCE_DIR}/inc/PoseDataSender.h"
    "${PROJECT_SOURCE_DIR}/inc/foxcontroller.h"
    "${PROJECT_SOURCE_DIR}/inc/previewitem.h"
    "${PROJECT_SOURCE_DIR}/inc/poseremapper.h"
    "${PROJECT_SOURCE_DIR}/inc/LogManager.h"
    inc/LogManager.h
    inc/ThemeManager.h
    src/LogManager.cpp
)

# SDL's SDL_main.h (pulled in transitively via QJoysticks) redefines `main`
# to `SDL_main`, which clobbers our real `main()` and breaks the Qt entry
# point library (Qt6::Main, the Qt6 successor of the old qtmain.lib).
# Tell SDL we already provide our own entry point.
target_compile_definitions(FOXTracker PRIVATE SDL_MAIN_HANDLED)

# Unlike Qt5, Qt6::Core no longer links the WinMain bootstrap automatically;
# WIN32 executables must link Qt6::Main themselves.
if(TARGET Qt6::Main)
    target_link_libraries(FOXTracker PRIVATE Qt6::Main)
endif()

target_include_directories(FOXTracker PRIVATE
    "${PROJECT_SOURCE_DIR}"
    "${PROJECT_SOURCE_DIR}/inc"
    "${PROJECT_SOURCE_DIR}/lib"
    "${PROJECT_BINARY_DIR}/generated"
)

target_link_libraries(FOXTracker PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
    Qt6::Widgets
    Qt6::Charts
    ${OpenCV_LIBS}
    Eigen3::Eigen
    ceres
    yaml-cpp::yaml-cpp
    dlib::dlib
    onnxruntime::onnxruntime
    libusb::libusb
    freetrack
    accela_filter
    ps3eye_driver
    QJoysticks
    UGlobalHotkey
)

if(WIN32)
    # ThemeManager sets DWMWA_USE_IMMERSIVE_DARK_MODE so the native title bar
    # follows the app's dark/light theme.
    target_link_libraries(FOXTracker PRIVATE dwmapi)
endif()

install(TARGETS FOXTracker
    RUNTIME DESTINATION bin
    BUNDLE DESTINATION .
)

# Keep runtime files beside the executable for the existing application path
# lookup in FlightAgxSettings. The directory copy deploys everything except
# the user's config: assets/config.yaml was renamed to config.template.yaml
# (a seed only) so that rebuilds never clobber settings saved by the app.
add_custom_command(TARGET FOXTracker POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E copy_directory_if_different
        "${PROJECT_SOURCE_DIR}/assets"
        "$<TARGET_FILE_DIR:FOXTracker>/assets"
    COMMAND "${CMAKE_COMMAND}"
        -DCONFIG_SRC=${PROJECT_SOURCE_DIR}/assets/config.template.yaml
        -DCONFIG_DST=$<TARGET_FILE_DIR:FOXTracker>/assets/config.yaml
        -P "${PROJECT_SOURCE_DIR}/cmake/deploy/ensure_config.cmake"
    COMMENT "Copying runtime assets"
    VERBATIM
)

# qt.conf next to the executable makes the deployment self-contained:
# plugins/ and qml/ are resolved relative to the exe directory instead of
# vcpkg's compiled-in absolute prefix (which only exists on this machine).
add_custom_command(TARGET FOXTracker POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        "${PROJECT_SOURCE_DIR}/cmake/deploy/qt.conf"
        "$<TARGET_FILE_DIR:FOXTracker>/qt.conf"
    COMMENT "Deploying qt.conf"
    VERBATIM
)

# QML modules deployed under qml/ are plugins whose backing Qt DLLs are NOT
# linked into FOXTracker.exe directly (e.g. import QtTest loads a qml/
# plugin that needs Qt6Test.dll). Copy each candidate when it exists in the
# vcpkg install tree; modules outside this project's dependency set simply
# won't be present, so the copy is skipped.
if(VCPKG_INSTALLED_DIR AND VCPKG_TARGET_TRIPLET)
    set(FOXTRACKER_QML_RUNTIME_DLLS
        Qt6Charts        # qml/QtCharts
        Qt6Multimedia    # qml/QtMultimedia
        Qt6MultimediaQuick
        Qt6Test          # qml/QtTest
        Qt6WebSockets    # qml/QtWebSockets
    )
    foreach(_dll ${FOXTRACKER_QML_RUNTIME_DLLS})
        if(EXISTS "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/bin/${_dll}.dll")
            add_custom_command(TARGET FOXTracker POST_BUILD
                COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                    "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/bin/${_dll}.dll"
                    "$<TARGET_FILE_DIR:FOXTracker>/"
                COMMENT "Deploying ${_dll}.dll"
                VERBATIM
            )
        endif()
        if(EXISTS "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/bin/${_dll}d.dll")
            add_custom_command(TARGET FOXTracker POST_BUILD
                COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                    "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/bin/${_dll}d.dll"
                    "$<TARGET_FILE_DIR:FOXTracker>/"
                COMMENT "Deploying ${_dll}d.dll (Debug)"
                VERBATIM
            )
        endif()
    endforeach()
endif()

# Qt's plugin tree must match the selected configuration, especially for Debug.
if(VCPKG_INSTALLED_DIR AND VCPKG_TARGET_TRIPLET)
    # copy_directory_if_different skips files whose content is unchanged, so
    # an incremental build does not try to rewrite plugin DLLs that a still-
    # running FOXTracker.exe keeps locked.
    add_custom_command(TARGET FOXTracker POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_directory_if_different
            "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}$<$<CONFIG:Debug>:/debug>/plugins"
            "$<TARGET_FILE_DIR:FOXTracker>/plugins"
        COMMENT "Deploying Qt plugins"
        VERBATIM
    )
    # The QML engine needs the QtQuick / QtQuick.Controls QML modules next to
    # the executable now that the UI is implemented in QML.
    add_custom_command(TARGET FOXTracker POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_directory_if_different
            "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}$<$<CONFIG:Debug>:/debug>/qml"
            "$<TARGET_FILE_DIR:FOXTracker>/qml"
        COMMENT "Deploying Qt QML modules"
        VERBATIM
    )
endif()
