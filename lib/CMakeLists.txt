file(GLOB FREETRACK_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/freetrack/*.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/freetrack/*.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/freetrack/csv/*.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/freetrack/freetrackclient/*.c"
)

add_library(freetrack STATIC ${FREETRACK_SOURCES})
target_include_directories(freetrack PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/freetrack"
    "${CMAKE_CURRENT_SOURCE_DIR}/freetrack/csv"
    "${CMAKE_CURRENT_SOURCE_DIR}/freetrack/freetrackclient"
    "${CMAKE_CURRENT_SOURCE_DIR}/accela_filter"
    "${PROJECT_SOURCE_DIR}"
    "${PROJECT_SOURCE_DIR}/inc"
)
target_link_libraries(freetrack PUBLIC
    Qt6::Core Qt6::Network Qt6::Widgets
    yaml-cpp::yaml-cpp Eigen3::Eigen ${OpenCV_LIBS}
)

file(GLOB ACCELA_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/accela_filter/*.cpp"
)

add_library(accela_filter STATIC ${ACCELA_SOURCES})
target_include_directories(accela_filter PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/accela_filter"
    "${PROJECT_SOURCE_DIR}/inc"
)
target_link_libraries(accela_filter PUBLIC
    Qt6::Core Eigen3::Eigen ${OpenCV_LIBS}
)

set(PS3EYE_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/PS3EYEDriver/src")
if(FOXTRACKER_ENABLE_PS3EYE AND EXISTS "${PS3EYE_SRC_DIR}/ps3eye.cpp")
    file(GLOB PS3EYE_SOURCES CONFIGURE_DEPENDS
        "${PS3EYE_SRC_DIR}/*.cpp"
        "${PS3EYE_SRC_DIR}/*.c"
    )
    add_library(ps3eye_driver STATIC ${PS3EYE_SOURCES})
    target_include_directories(ps3eye_driver PUBLIC "${PS3EYE_SRC_DIR}")
    target_link_libraries(ps3eye_driver PUBLIC libusb::libusb)
    message(STATUS "PS3EYEDriver enabled")
else()
    add_library(ps3eye_driver INTERFACE)
    target_include_directories(ps3eye_driver INTERFACE
        "${PROJECT_SOURCE_DIR}/cmake/ps3eye_stub"
        "${PROJECT_SOURCE_DIR}"
    )
    if(FOXTRACKER_ENABLE_PS3EYE)
        message(STATUS "PS3EYEDriver submodule unavailable; using stub headers")
    else()
        message(STATUS "PS3EYEDriver disabled; using stub headers")
    endif()
endif()
