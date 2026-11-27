# cmake/CompilerOptions.cmake
include_guard(GLOBAL)

option(ENABLE_GPROF "Enable profiling with gprof" OFF)

if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Choose the type of build." FORCE)
endif()

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(
            -Wall
            -Wextra
            -Werror
    )
    add_compile_options(
            $<$<CONFIG:Debug>:-O0>
            $<$<CONFIG:Debug>:-g3>
            $<$<CONFIG:Debug>:-Wno-unused-parameter>
            $<$<CONFIG:Debug>:-Wno-unused-variable>
            $<$<CONFIG:Debug>:-Wno-unused-const-variable>
    )
    add_compile_options(
            $<$<NOT:$<CONFIG:Debug>>:-O3>
    )
    if(ENABLE_GPROF)
        add_compile_options(-pg)
        add_link_options(-pg)
    else()
        add_compile_options($<$<NOT:$<CONFIG:Debug>>:-flto>)
        add_link_options($<$<NOT:$<CONFIG:Debug>>:-flto>)
    endif()
endif()
