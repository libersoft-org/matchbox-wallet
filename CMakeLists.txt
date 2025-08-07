cmake_minimum_required(VERSION 3.16)
project(Wallet VERSION 1.0.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
find_package(Qt6 REQUIRED COMPONENTS Core Quick Svg)
find_package(Qt6 QUIET COMPONENTS Multimedia)

# Find Node.js for embedding
find_path(NODEJS_INCLUDE_DIR 
    NAMES node.h
    HINTS /usr/include/node /usr/local/include/node /opt/homebrew/include/node
    PATH_SUFFIXES nodejs node
)

find_library(NODEJS_LIBRARY 
    NAMES node libnode
    HINTS /usr/lib /usr/local/lib /opt/homebrew/lib
    PATH_SUFFIXES x86_64-linux-gnu
)

find_library(V8_LIBRARY 
    NAMES v8 libv8
    HINTS /usr/lib /usr/local/lib /opt/homebrew/lib
    PATH_SUFFIXES x86_64-linux-gnu
)

find_library(V8_LIBBASE_LIBRARY 
    NAMES v8_libbase libv8_libbase
    HINTS /usr/lib /usr/local/lib /opt/homebrew/lib
    PATH_SUFFIXES x86_64-linux-gnu
)

find_library(V8_LIBPLATFORM_LIBRARY 
    NAMES v8_libplatform libv8_libplatform
    HINTS /usr/lib /usr/local/lib /opt/homebrew/lib
    PATH_SUFFIXES x86_64-linux-gnu
)

find_library(UV_LIBRARY 
    NAMES uv libuv
    HINTS /usr/lib /usr/local/lib /opt/homebrew/lib
    PATH_SUFFIXES x86_64-linux-gnu
)

if(NOT NODEJS_INCLUDE_DIR OR NOT NODEJS_LIBRARY)
    message(FATAL_ERROR "Node.js development files not found. Please install nodejs-dev or libnode-dev package.")
endif()

message(STATUS "Found Node.js headers: ${NODEJS_INCLUDE_DIR}")
message(STATUS "Found Node.js library: ${NODEJS_LIBRARY}")
set(QT_QML_GENERATE_QMLLS_INI ON)
qt_standard_project_setup()
qt_add_executable(Wallet
 src/main.cpp
 src/include/wifimanager.h
 src/wifimanager.cpp
 src/include/systemmanager.h
 src/systemmanager.cpp
 src/include/node.h
 src/node.cpp
)

target_include_directories(Wallet PRIVATE
 src
 ${NODEJS_INCLUDE_DIR}
)

# Automatically find all QML files with relative paths
file(GLOB_RECURSE QML_FILES_LIST RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "src/qml/*.qml")

# Find all SVG files in img directory
file(GLOB_RECURSE SVG_FILES_LIST RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "src/img/*.svg")

# Find all JSON translation files
file(GLOB_RECURSE JSON_FILES_LIST RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "src/qml/translations/*.json")

# Add QML module to the executable
qt_add_qml_module(Wallet
 URI WalletModule
 VERSION 1.0
 NO_GENERATE_QMLTYPES
 NO_CACHEGEN
 NO_LINT
 QML_FILES ${QML_FILES_LIST}
 RESOURCES ${SVG_FILES_LIST} ${JSON_FILES_LIST}
)
target_link_libraries(Wallet PRIVATE
 Qt6::Core
 Qt6::Quick
 Qt6::Svg
 ${NODEJS_LIBRARY}
 ${V8_LIBRARY}
 ${V8_LIBBASE_LIBRARY}
 ${V8_LIBPLATFORM_LIBRARY}
 ${UV_LIBRARY}
)

# Link Qt6::Multimedia if available
if(TARGET Qt6::Multimedia)
 target_link_libraries(Wallet PRIVATE Qt6::Multimedia)
 target_compile_definitions(Wallet PRIVATE HAVE_QT_MULTIMEDIA)
 message(STATUS "Qt6Multimedia found - camera support enabled")
else()
 message(WARNING "Qt6Multimedia not found - camera support disabled")
endif()
# Platform specific settings
if(WIN32)
 set_property(TARGET Wallet PROPERTY WIN32_EXECUTABLE TRUE)
 set_target_properties(Wallet PROPERTIES OUTPUT_NAME "wallet")
else()
 # Linux/Unix - set output name to lowercase
 set_target_properties(Wallet PROPERTIES OUTPUT_NAME "wallet")
endif()
# Set application properties
set_target_properties(Wallet PROPERTIES
 MACOSX_BUNDLE_GUI_IDENTIFIER org.libersoft.matchbox-wallet
 MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
 MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
 MACOSX_BUNDLE TRUE
 WIN32_EXECUTABLE TRUE
)
