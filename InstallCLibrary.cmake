# cmake/InstallCLibrary.cmake
include_guard(GLOBAL)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

function(setup_c_library_install TARGET_NAME)
    cmake_parse_arguments(ARG "" "C_STANDARD" "DEPENDENCIES" ${ARGN})

    if(NOT DEFINED ARG_C_STANDARD)
        set(ARG_C_STANDARD 23)
    endif()

    set_target_properties(${TARGET_NAME} PROPERTIES
            C_STANDARD ${ARG_C_STANDARD}
            C_STANDARD_REQUIRED ON
            VERSION ${PROJECT_VERSION}
            SOVERSION ${PROJECT_VERSION_MAJOR}
    )

    set(_cmake_install_dir "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET_NAME}")

    install(TARGETS ${TARGET_NAME}
            EXPORT ${TARGET_NAME}Targets
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )

    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include")
        install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include/"
                DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        )
    endif()

    install(EXPORT ${TARGET_NAME}Targets
            FILE ${TARGET_NAME}Targets.cmake
            NAMESPACE ${TARGET_NAME}::
            DESTINATION ${_cmake_install_dir}
    )

    write_basic_package_version_file(
            "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}ConfigVersion.cmake"
            VERSION ${PROJECT_VERSION}
            COMPATIBILITY SameMajorVersion
    )

    set(_find_deps_code "")
    if(ARG_DEPENDENCIES)
        string(APPEND _find_deps_code "include(CMakeFindDependencyMacro)\n")
        foreach(_dep IN LISTS ARG_DEPENDENCIES)
            string(APPEND _find_deps_code "find_dependency(${_dep})\n")
        endforeach()
    endif()

    set(_config_in "${CMAKE_CURRENT_SOURCE_DIR}/cmake/${TARGET_NAME}Config.cmake.in")
    if(NOT EXISTS "${_config_in}")
        set(_config_in "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}Config.cmake.in")
        file(WRITE "${_config_in}"
                "@PACKAGE_INIT@\n\n${_find_deps_code}\ninclude(\"\${CMAKE_CURRENT_LIST_DIR}/${TARGET_NAME}Targets.cmake\")\n"
        )
    endif()

    configure_package_config_file(
            "${_config_in}"
            "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}Config.cmake"
            INSTALL_DESTINATION ${_cmake_install_dir}
    )

    install(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}Config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}ConfigVersion.cmake"
            DESTINATION ${_cmake_install_dir}
    )
endfunction()
