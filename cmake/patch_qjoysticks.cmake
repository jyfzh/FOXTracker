# Script to patch QJoysticks CMakeLists.txt for Qt5 compatibility
# Called from FetchContent_Declare PATCH_COMMAND.

if(NOT QJOYSTICKS_SOURCE_DIR)
    message(FATAL_ERROR "QJOYSTICKS_SOURCE_DIR must point to the QJoysticks submodule")
endif()

set(patch_file "${QJOYSTICKS_SOURCE_DIR}/CMakeLists.txt")

# Read the original file
file(READ "${patch_file}" content)

# Replace Qt6 with Qt5
string(REPLACE "find_package(Qt6 " "find_package(Qt5 " content "${content}")
string(REPLACE "Qt6::Core" "Qt5::Core" content "${content}")
string(REPLACE "Qt6::Gui" "Qt5::Gui" content "${content}")
string(REPLACE "Qt6::Widgets" "Qt5::Widgets" content "${content}")

# Write back
file(WRITE "${patch_file}" "${content}")

message(STATUS "QJoysticks patched: Qt6 references replaced with Qt5")
