include_guard(GLOBAL)

find_package(Qt5 REQUIRED COMPONENTS Core Gui Qml Quick Network Widgets Charts)
find_package(OpenCV REQUIRED COMPONENTS
    core imgproc imgcodecs video videoio highgui calib3d features2d dnn tracking aruco
)
find_package(Eigen3 REQUIRED)
find_package(Ceres REQUIRED)
find_package(yaml-cpp REQUIRED)
find_package(dlib REQUIRED)
find_package(onnxruntime REQUIRED)
find_package(libusb REQUIRED)

# dlib publishes /bigobj through its interface. GNU-style drivers reject it,
# while MSVC and clang-cl accept it.
if(NOT MSVC AND TARGET dlib::dlib)
    get_target_property(_dlib_compile_options dlib::dlib INTERFACE_COMPILE_OPTIONS)
    if(_dlib_compile_options)
        string(REPLACE "/bigobj" "" _dlib_compile_options "${_dlib_compile_options}")
        set_target_properties(dlib::dlib PROPERTIES
            INTERFACE_COMPILE_OPTIONS "${_dlib_compile_options}"
        )
    endif()
endif()
unset(_dlib_compile_options)

# ONNX Runtime 1.17 removed the old provider factory headers. Keep local
# compatibility headers until the source no longer includes them.
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/generated")
foreach(_provider cuda tensorrt)
    file(WRITE "${CMAKE_BINARY_DIR}/generated/${_provider}_provider_factory.h"
        "#pragma once\n"
        "#include <onnxruntime_cxx_api.h>\n"
        "// Compatibility header for older provider includes.\n"
    )
endforeach()
unset(_provider)

# These dependencies are kept as git submodules so builds do not download
# mutable content during CMake configuration. QJoysticks is temporarily
# patched for Qt5 below and restored right after add_subdirectory, so the
# submodule working tree stays clean.
set(QJOYSTICKS_SOURCE_DIR "${PROJECT_SOURCE_DIR}/lib/QJoysticks")
set(UGLOBALHOTKEY_SOURCE_DIR "${PROJECT_SOURCE_DIR}/lib/UGlobalHotkey")

if(NOT EXISTS "${QJOYSTICKS_SOURCE_DIR}/CMakeLists.txt")
    message(FATAL_ERROR
        "QJoysticks submodule is missing. Run: git submodule update --init --recursive"
    )
endif()

# QJoysticks currently declares Qt6 targets while FOXTracker uses Qt5.
execute_process(
    COMMAND "${CMAKE_COMMAND}"
        "-DQJOYSTICKS_SOURCE_DIR=${QJOYSTICKS_SOURCE_DIR}"
        "-DQJOYSTICKS_ORIG_FILE=${CMAKE_BINARY_DIR}/QJoysticks_CMakeLists_orig.txt"
        -P "${PROJECT_SOURCE_DIR}/cmake/patch_qjoysticks.cmake"
    RESULT_VARIABLE _qjoysticks_patch_result
)
if(NOT _qjoysticks_patch_result EQUAL 0)
    message(FATAL_ERROR "Failed to patch QJoysticks for Qt5")
endif()
unset(_qjoysticks_patch_result)

set(QJOYSTICKS_INSTALL OFF CACHE BOOL "" FORCE)
set(QJOYSTICKS_BUILD_SHARED OFF CACHE BOOL "" FORCE)
add_subdirectory("${QJOYSTICKS_SOURCE_DIR}" "${CMAKE_BINARY_DIR}/QJoysticks")

# add_subdirectory consumed the patched CMakeLists.txt. Restore the original
# so the submodule working tree stays clean; otherwise `git submodule update`
# would silently revert the patch and break future configures.
file(READ "${CMAKE_BINARY_DIR}/QJoysticks_CMakeLists_orig.txt" _qj_orig)
file(WRITE "${QJOYSTICKS_SOURCE_DIR}/CMakeLists.txt" "${_qj_orig}")
file(READ "${QJOYSTICKS_SOURCE_DIR}/CMakeLists.txt" _qj_restored)
if(NOT _qj_restored STREQUAL _qj_orig)
    message(FATAL_ERROR
        "Failed to restore ${QJOYSTICKS_SOURCE_DIR}/CMakeLists.txt after patching; "
        "the QJoysticks submodule working tree is dirty. "
        "Run: git -C lib/QJoysticks checkout -- CMakeLists.txt"
    )
endif()
unset(_qj_restored)
unset(_qj_orig)

if(NOT EXISTS "${UGLOBALHOTKEY_SOURCE_DIR}/uglobalhotkeys.cpp")
    message(FATAL_ERROR
        "UGlobalHotkey submodule is missing. Run: git submodule update --init --recursive"
    )
endif()

# UGlobalHotkey has no CMake project, so expose its small source set as a
# normal target from the checked-out submodule.
add_library(UGlobalHotkey STATIC
    "${UGLOBALHOTKEY_SOURCE_DIR}/uglobalhotkeys.h"
    "${UGLOBALHOTKEY_SOURCE_DIR}/uglobalhotkeys.cpp"
    "${UGLOBALHOTKEY_SOURCE_DIR}/ukeysequence.h"
    "${UGLOBALHOTKEY_SOURCE_DIR}/ukeysequence.cpp"
    "${UGLOBALHOTKEY_SOURCE_DIR}/uexception.h"
    "${UGLOBALHOTKEY_SOURCE_DIR}/uexception.cpp"
    "${UGLOBALHOTKEY_SOURCE_DIR}/hotkeymap.h"
    "${UGLOBALHOTKEY_SOURCE_DIR}/uglobal.h"
)
target_include_directories(UGlobalHotkey PUBLIC "${UGLOBALHOTKEY_SOURCE_DIR}")
target_compile_definitions(UGlobalHotkey PUBLIC UGLOBALHOTKEY_LIBRARY)
target_link_libraries(UGlobalHotkey PUBLIC Qt5::Core Qt5::Gui Qt5::Widgets)
