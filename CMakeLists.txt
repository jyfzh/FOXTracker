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
)

# SDL's SDL_main.h (pulled in transitively via QJoysticks) redefines `main`
# to `SDL_main`, which clobbers our real `main()` and breaks Qt's WinMain
# (from qtmain.lib). Tell SDL we already provide our own entry point.
target_compile_definitions(FOXTracker PRIVATE SDL_MAIN_HANDLED)

target_include_directories(FOXTracker PRIVATE
    "${PROJECT_SOURCE_DIR}"
    "${PROJECT_SOURCE_DIR}/inc"
    "${PROJECT_SOURCE_DIR}/lib"
    "${PROJECT_BINARY_DIR}/generated"
)

target_link_libraries(FOXTracker PRIVATE
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::Network
    Qt5::Widgets
    Qt5::Charts
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

install(TARGETS FOXTracker
    RUNTIME DESTINATION bin
    BUNDLE DESTINATION .
)

# Keep runtime files beside the executable for the existing application path
# lookup in FlightAgxSettings. config.yaml lives inside assets/, so the
# whole directory copy covers it.
add_custom_command(TARGET FOXTracker POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E copy_directory
        "${PROJECT_SOURCE_DIR}/assets"
        "$<TARGET_FILE_DIR:FOXTracker>/assets"
    COMMENT "Copying runtime assets"
    VERBATIM
)

# Qt's plugin tree must match the selected configuration, especially for Debug.
if(VCPKG_INSTALLED_DIR AND VCPKG_TARGET_TRIPLET)
    add_custom_command(TARGET FOXTracker POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E rm -rf
            "$<TARGET_FILE_DIR:FOXTracker>/plugins"
        COMMAND "${CMAKE_COMMAND}" -E copy_directory
            "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}$<$<CONFIG:Debug>:/debug>/plugins"
            "$<TARGET_FILE_DIR:FOXTracker>/plugins"
        COMMENT "Deploying Qt plugins"
        VERBATIM
    )
    # The QML engine needs the QtQuick / QtQuick.Controls QML modules next to
    # the executable now that the UI is implemented in QML.
    add_custom_command(TARGET FOXTracker POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E rm -rf
            "$<TARGET_FILE_DIR:FOXTracker>/qml"
        COMMAND "${CMAKE_COMMAND}" -E copy_directory
            "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}$<$<CONFIG:Debug>:/debug>/qml"
            "$<TARGET_FILE_DIR:FOXTracker>/qml"
        COMMENT "Deploying Qt QML modules"
        VERBATIM
    )
endif()
