
# cmake/SetupCTesting.cmake
include_guard(GLOBAL)

function(setup_c_testing TARGET_NAME)
    cmake_parse_arguments(ARG "" "PREFIX;TEST_DIR" "" ${ARGN})

    if(NOT DEFINED ARG_PREFIX)
        set(_prefix "${TARGET_NAME}_")
    else()
        set(_prefix "${ARG_PREFIX}")
    endif()

    if(NOT DEFINED ARG_TEST_DIR)
        set(_test_dir "test")
    else()
        set(_test_dir "${ARG_TEST_DIR}")
    endif()

    if(ENABLE_TEST_COV)
        enable_testing()

        target_link_libraries(${TARGET_NAME} PRIVATE gcov)
        target_compile_options(${TARGET_NAME} PRIVATE "-fprofile-arcs" "-ftest-coverage" "--coverage")
        target_link_options(${TARGET_NAME} PRIVATE "-fprofile-arcs" "-ftest-coverage" "--coverage")

        file(GLOB_RECURSE _testcase_src
            RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
            "${_test_dir}/testcases/*.c"
            "${_test_dir}/testcases/*.h"
        )

        set(_unittest_target "${_prefix}unittest")
        add_executable(${_unittest_target} "${_test_dir}/test.c" ${_testcase_src})

        target_compile_definitions(${_unittest_target} PRIVATE
            $<$<BOOL:${ENABLE_TEST_COV}>:_TEST_LOCAL_API_>
        )
        target_include_directories(${_unittest_target} PRIVATE "${_test_dir}/testcases")
        target_link_libraries(${_unittest_target} PRIVATE check gcov ${TARGET_NAME})

        if(GITHUB_CI)
            target_link_libraries(${_unittest_target} PRIVATE subunit)
        endif()

        target_compile_options(${_unittest_target} PRIVATE "--coverage")
        target_link_options(${_unittest_target} PRIVATE "--coverage")

        add_test(NAME "${_prefix}UnitTests" COMMAND ${_unittest_target})

        find_program(LCOV_PATH lcov)
        find_program(GENHTML_PATH genhtml)
        if(LCOV_PATH AND GENHTML_PATH)
            set(_cov_target "${_prefix}coverage")
            set(_cov_info "${CMAKE_CURRENT_BINARY_DIR}/coverage.info")
            set(_cov_filtered "${CMAKE_CURRENT_BINARY_DIR}/coverage_filtered.info")
            set(_cov_html_dir "${CMAKE_CURRENT_BINARY_DIR}/coverage_html")

            add_custom_target(${_cov_target}
                COMMAND ${LCOV_PATH} --directory "${CMAKE_CURRENT_BINARY_DIR}" --zerocounters
                COMMAND ${CMAKE_CTEST_COMMAND} -R "^${_prefix}UnitTests$" --output-on-failure
                COMMAND ${LCOV_PATH} --directory "${CMAKE_CURRENT_BINARY_DIR}" --capture --output-file "${_cov_info}"
                COMMAND ${LCOV_PATH} --remove "${_cov_info}" "${CMAKE_CURRENT_SOURCE_DIR}/${_test_dir}/*" "/usr/*" --ignore-errors unused --output-file "${_cov_filtered}"
                COMMAND ${GENHTML_PATH} "${_cov_filtered}" --output-directory "${_cov_html_dir}"
                WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
                COMMENT "Generating coverage report for ${TARGET_NAME}..."
                VERBATIM
            )
            add_dependencies(${_cov_target} ${_unittest_target})

            if(NOT TARGET coverage)
                add_custom_target(coverage)
            endif()
            add_dependencies(coverage ${_cov_target})
        else()
            message(WARNING "lcov or genhtml not found, ${_prefix}coverage target disabled")
        endif()
    endif()

    string(TOUPPER "${CMAKE_BUILD_TYPE}" _build_type_upper)
    if(_build_type_upper STREQUAL "DEBUG" OR BUILD_TYPE_UPPER STREQUAL "DEBUG")
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${_test_dir}/debug.c")
            set(_debug_target "${_prefix}debug")
            add_executable(${_debug_target} "${_test_dir}/debug.c")
            target_link_libraries(${_debug_target} PRIVATE ${TARGET_NAME})
            target_compile_definitions(${_debug_target} PRIVATE "_TEST_LOCAL_API_")
        endif()
    endif()
endfunction()
