# Seeds $CONFIG_DST from $CONFIG_SRC (the template shipped in the repo)
# only when the destination does not exist yet. The app owns config.yaml
# afterwards: it may rewrite it at runtime, and rebuilds must never clobber
# the user's saved settings.
if(NOT EXISTS "${CONFIG_DST}")
    message(STATUS "Seeding config: ${CONFIG_DST}")
    execute_process(COMMAND "${CMAKE_COMMAND}" -E copy "${CONFIG_SRC}" "${CONFIG_DST}")
endif()
