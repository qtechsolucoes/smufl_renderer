cmake_minimum_required(VERSION 3.15)
project(verovio_flutter VERSION 0.0.1 LANGUAGES CXX)

# C++20 standard required for Verovio
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Verovio configuration flags
option(NO_DARMS_SUPPORT         "Disable DARMS support"                        ON)
option(NO_PAE_SUPPORT           "Disable Plaine & Easie support"               ON)
option(NO_ABC_SUPPORT           "Disable ABC support"                          ON)
option(NO_MUSICXML_SUPPORT      "Disable MusicXML support"                     OFF)
option(NO_MXL_SUPPORT           "Disable compressed MusicXML support"          ON)
option(NO_HUMDRUM_SUPPORT       "Disable Humdrum support"                      ON)
option(NO_EDIT_SUPPORT          "Disable editor code"                          ON)
option(NO_RUNTIME               "Disable runtime clock support"                ON)

# Verovio paths
set(VEROVIO_ROOT ${CMAKE_SOURCE_DIR}/../../../../verovio_real)

# Include directories for Verovio
include_directories(
    ${VEROVIO_ROOT}/include
    ${VEROVIO_ROOT}/include/crc
    ${VEROVIO_ROOT}/include/midi
    ${VEROVIO_ROOT}/include/hum
    ${VEROVIO_ROOT}/include/json
    ${VEROVIO_ROOT}/include/pugi
    ${VEROVIO_ROOT}/include/zip
    ${VEROVIO_ROOT}/include/vrv
    ${VEROVIO_ROOT}/libmei/dist
    ${VEROVIO_ROOT}/libmei/addons
    ${CMAKE_SOURCE_DIR}/../../../../src
)

# Source files from Verovio
file(GLOB verovio_SRC "${VEROVIO_ROOT}/src/*.cpp")
file(GLOB libmei_dist_SRC "${VEROVIO_ROOT}/libmei/dist/*.cpp")
file(GLOB libmei_addons_SRC "${VEROVIO_ROOT}/libmei/addons/*.cpp")
file(GLOB midi_SRC "${VEROVIO_ROOT}/src/midi/*.cpp")
file(GLOB crc_SRC "${VEROVIO_ROOT}/src/crc/*.cpp")

# Remove editor-related files that conflict with NO_EDIT_SUPPORT
list(REMOVE_ITEM verovio_SRC
    "${VEROVIO_ROOT}/src/editfunctor.cpp"
    "${VEROVIO_ROOT}/src/editortoolkit_cmn.cpp"
    "${VEROVIO_ROOT}/src/editortoolkit_neume.cpp"
    "${VEROVIO_ROOT}/src/editortoolkit_mensural.cpp"
)

# Conditional Humdrum support
if(NOT NO_HUMDRUM_SUPPORT)
    file(GLOB hum_SRC "${VEROVIO_ROOT}/src/hum/*.cpp")
endif()

# All Verovio source files
set(all_verovio_SRC
    ${verovio_SRC}
    ${libmei_dist_SRC}
    ${libmei_addons_SRC}
    ${hum_SRC}
    ${crc_SRC}
    ${midi_SRC}
    ${VEROVIO_ROOT}/src/json/jsonxx.cc
    ${VEROVIO_ROOT}/src/pugi/pugixml.cpp
)

# Create the shared library with our Flutter wrapper + Verovio
add_library(verovio_flutter SHARED
    ${CMAKE_SOURCE_DIR}/../../../../src/verovio_flutter.cpp
    ${all_verovio_SRC}
)

# Compiler definitions
target_compile_definitions(verovio_flutter PRIVATE
    DART_SHARED_LIB
    ANDROID
    VEROVIO_REAL_IMPLEMENTATION
)

# Apply Verovio feature flags
if(NO_DARMS_SUPPORT)
    target_compile_definitions(verovio_flutter PRIVATE NO_DARMS_SUPPORT)
endif()

if(NO_PAE_SUPPORT)
    target_compile_definitions(verovio_flutter PRIVATE NO_PAE_SUPPORT)
endif()

if(NO_ABC_SUPPORT)
    target_compile_definitions(verovio_flutter PRIVATE NO_ABC_SUPPORT)
endif()

if(NO_MUSICXML_SUPPORT)
    target_compile_definitions(verovio_flutter PRIVATE NO_MUSICXML_SUPPORT)
endif()

if(NO_MXL_SUPPORT)
    target_compile_definitions(verovio_flutter PRIVATE NO_MXL_SUPPORT)
endif()

if(NO_HUMDRUM_SUPPORT)
    target_compile_definitions(verovio_flutter PRIVATE NO_HUMDRUM_SUPPORT)
endif()

if(NO_EDIT_SUPPORT)
    target_compile_definitions(verovio_flutter PRIVATE NO_EDIT_SUPPORT)
endif()

if(NO_RUNTIME)
    target_compile_definitions(verovio_flutter PRIVATE NO_RUNTIME)
endif()

# Compiler flags for Android
target_compile_options(verovio_flutter PRIVATE
    -Wall -W -pedantic
    -Wno-unused-parameter
    -Wno-dollar-in-identifier-extension
    -Wno-conversion
    -Wno-float-conversion
    -Wno-missing-braces
    -Wno-missing-field-initializers
    -Wno-overloaded-virtual
    -Wno-shadow
    -Wno-sign-conversion
    -Wno-trigraphs
    -Wno-unknown-pragmas
    -Wno-unused-label
    -Wparentheses
    -Wswitch
    -Wuninitialized
    -Wunreachable-code
    -Wunused-function
    -Wunused-value
    -Wunused-variable
    -std=c++20
    -fPIC
)

# Set properties
set_target_properties(verovio_flutter PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
    POSITION_INDEPENDENT_CODE ON
)

# Android specific linking
find_library(log-lib log)
target_link_libraries(verovio_flutter ${log-lib})

# Linker flags for Android optimization
set_target_properties(verovio_flutter PROPERTIES
    LINK_FLAGS "-Wl,-z,max-page-size=0x4000"
)