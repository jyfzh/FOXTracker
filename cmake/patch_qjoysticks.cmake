# Script to patch QJoysticks CMakeLists.txt for Qt5 compatibility
# Called from Dependencies.cmake via execute_process. The unmodified content is
# also saved to QJOYSTICKS_ORIG_FILE so the caller can restore the submodule
# working tree after add_subdirectory has consumed the patched file.

if(NOT QJOYSTICKS_SOURCE_DIR)
    message(FATAL_ERROR "QJOYSTICKS_SOURCE_DIR must point to the QJoysticks submodule")
endif()
if(NOT QJOYSTICKS_ORIG_FILE)
    message(FATAL_ERROR "QJOYSTICKS_ORIG_FILE must point to where the original CMakeLists.txt is saved")
endif()

set(patch_file "${QJOYSTICKS_SOURCE_DIR}/CMakeLists.txt")

# Read the original file
file(READ "${patch_file}" content)

# The working tree must be pristine before patching. If a previous configure
# failed between patching and restoring, the file already says Qt5 and the
# "clean" copy saved below would be the patched text, silently keeping the
# submodule dirty. Fail loudly instead so the user can restore it.
if(NOT content MATCHES "Qt6")
    message(FATAL_ERROR
        "${patch_file} does not reference Qt6 - the QJoysticks submodule is "
        "already patched. Restore it with: "
        "git -C ${QJOYSTICKS_SOURCE_DIR} checkout -- CMakeLists.txt"
    )
endif()

# Save the unmodified content before patching, so the caller can restore the
# submodule working tree (keep this build from dirtying it).
file(WRITE "${QJOYSTICKS_ORIG_FILE}" "${content}")

# Replace Qt6 with Qt5
string(REPLACE "find_package(Qt6 " "find_package(Qt5 " content "${content}")
string(REPLACE "Qt6::Core" "Qt5::Core" content "${content}")
string(REPLACE "Qt6::Gui" "Qt5::Gui" content "${content}")
string(REPLACE "Qt6::Widgets" "Qt5::Widgets" content "${content}")

# Write back
file(WRITE "${patch_file}" "${content}")

message(STATUS "QJoysticks patched: Qt6 references replaced with Qt5")
