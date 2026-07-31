# Findlibusb.cmake
# Finds libusb-1.0 from vcpkg (or system) and creates the libusb::libusb target.
#
# This module is needed because vcpkg's libusb port does not ship CMake config files.
#
# Variables:
#   libusb_FOUND
#   libusb_INCLUDE_DIR
#   libusb_LIBRARY
#
# Imported target:
#   libusb::libusb

find_path(libusb_INCLUDE_DIR
    NAMES libusb-1.0/libusb.h
    PATHS
        "${CMAKE_PREFIX_PATH}/include"
        "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/include"
        "$ENV{VCPKG_ROOT}/installed/${VCPKG_TARGET_TRIPLET}/include"
)

# PS3EYEDriver source uses #include "libusb.h" (no -1.0 prefix),
# so we also need the subdirectory in the include path.
set(libusb_INCLUDE_DIRS
    "${libusb_INCLUDE_DIR}"
    "${libusb_INCLUDE_DIR}/libusb-1.0"
)

# On Windows, the lib is named libusb-1.0.lib (or libusb-1.0.dll for dynamic)
find_library(libusb_LIBRARY
    NAMES libusb-1.0 usb-1.0
    PATHS
        "${CMAKE_PREFIX_PATH}/lib"
        "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib"
        "$ENV{VCPKG_ROOT}/installed/${VCPKG_TARGET_TRIPLET}/lib"
)

# Also try debug suffix
find_library(libusb_LIBRARY_DEBUG
    NAMES libusb-1.0d usb-1.0d
    PATHS
        "${CMAKE_PREFIX_PATH}/debug/lib"
        "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug/lib"
        "$ENV{VCPKG_ROOT}/installed/${VCPKG_TARGET_TRIPLET}/debug/lib"
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(libusb
    REQUIRED_VARS libusb_INCLUDE_DIR libusb_LIBRARY
)

if(libusb_FOUND AND NOT TARGET libusb::libusb)
    add_library(libusb::libusb UNKNOWN IMPORTED)
    set_target_properties(libusb::libusb PROPERTIES
        IMPORTED_LOCATION "${libusb_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${libusb_INCLUDE_DIRS}"
    )
    if(libusb_LIBRARY_DEBUG AND NOT CMAKE_CONFIGURATION_TYPES)
        set_target_properties(libusb::libusb PROPERTIES
            IMPORTED_LOCATION_DEBUG "${libusb_LIBRARY_DEBUG}"
        )
    endif()

    # Try to find the DLL next to the import lib
    if(WIN32 AND libusb_LIBRARY MATCHES "\\.lib$")
        get_filename_component(libusb_LIB_DIR "${libusb_LIBRARY}" DIRECTORY)
        file(GLOB libusb_DLLS "${libusb_LIB_DIR}/libusb-1*.dll")
        if(libusb_DLLS)
            set_target_properties(libusb::libusb PROPERTIES
                IMPORTED_LOCATION "${libusb_LIBRARY}"
            )
        endif()
    endif()

    mark_as_advanced(libusb_INCLUDE_DIR libusb_LIBRARY libusb_LIBRARY_DEBUG)
endif()
