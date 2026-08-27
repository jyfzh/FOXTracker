include_guard(GLOBAL)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Network Widgets Charts)
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
# mutable content during CMake configuration.
set(QJOYSTICKS_SOURCE_DIR "${PROJECT_SOURCE_DIR}/lib/QJoysticks")
set(UGLOBALHOTKEY_SOURCE_DIR "${PROJECT_SOURCE_DIR}/lib/UGlobalHotkey")

if(NOT EXISTS "${QJOYSTICKS_SOURCE_DIR}/CMakeLists.txt")
    message(FATAL_ERROR
        "QJoysticks submodule is missing. Run: git submodule update --init --recursive"
    )
endif()

set(QJOYSTICKS_INSTALL OFF CACHE BOOL "" FORCE)
set(QJOYSTICKS_BUILD_SHARED OFF CACHE BOOL "" FORCE)
add_subdirectory("${QJOYSTICKS_SOURCE_DIR}" "${CMAKE_BINARY_DIR}/QJoysticks")

if(NOT EXISTS "${UGLOBALHOTKEY_SOURCE_DIR}/uglobalhotkeys.cpp")
    message(FATAL_ERROR
        "UGlobalHotkey submodule is missing. Run: git submodule update --init --recursive"
    )
endif()

# UGlobalHotkey has no CMake project, so expose its small source set as a
# normal target from the checked-out submodule. Upstream still uses the Qt5
# nativeEvent signature (long *result); Qt6 changed it to qintptr *. Copy the
# sources into the binary dir with that substitution applied instead of
# dirtying the submodule working tree.
set(UGLOBALHOTKEY_PATCHED_DIR "${CMAKE_BINARY_DIR}/generated/UGlobalHotkey")
file(MAKE_DIRECTORY "${UGLOBALHOTKEY_PATCHED_DIR}")
set(UGLOBALHOTKEY_FILES
    uglobalhotkeys.h uglobalhotkeys.cpp
    ukeysequence.h ukeysequence.cpp
    uexception.h uexception.cpp
    hotkeymap.h uglobal.h
)
set(UGLOBALHOTKEY_PATCHED_SOURCES "")
foreach(_ugh_file ${UGLOBALHOTKEY_FILES})
    file(READ "${UGLOBALHOTKEY_SOURCE_DIR}/${_ugh_file}" _ugh_content)
    string(REPLACE "long *" "qintptr *" _ugh_content "${_ugh_content}")
    file(WRITE "${UGLOBALHOTKEY_PATCHED_DIR}/${_ugh_file}" "${_ugh_content}")
    list(APPEND UGLOBALHOTKEY_PATCHED_SOURCES "${UGLOBALHOTKEY_PATCHED_DIR}/${_ugh_file}")
endforeach()
unset(_ugh_file)
unset(_ugh_content)

add_library(UGlobalHotkey STATIC ${UGLOBALHOTKEY_PATCHED_SOURCES})
target_include_directories(UGlobalHotkey PUBLIC "${UGLOBALHOTKEY_PATCHED_DIR}")
target_compile_definitions(UGlobalHotkey PUBLIC UGLOBALHOTKEY_LIBRARY)
target_link_libraries(UGlobalHotkey PUBLIC Qt6::Core Qt6::Gui Qt6::Widgets)
