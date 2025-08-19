cmake_minimum_required(VERSION 3.16)
project(Wallet VERSION 1.0.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Option to enable/disable Node.js integration
option(ENABLE_NODEJS "Enable Node.js integration" ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Svg)
find_package(Qt6 QUIET COMPONENTS Multimedia VirtualKeyboard)

# Node.js integration (conditional)
if(ENABLE_NODEJS)

	find_path(NODEJS_INCLUDE_DIR
		NAMES node.h
		HINTS /usr/include/node /usr/include/nodejs /usr/local/include/node /opt/homebrew/include/node
		PATH_SUFFIXES nodejs node
	)

	find_library(NODEJS_LIBRARY 
		NAMES node libnode
		HINTS /usr/lib /usr/local/lib /opt/homebrew/lib
		PATH_SUFFIXES x86_64-linux-gnu
	)

	message(STATUS "Found Node.js headers: ${NODEJS_INCLUDE_DIR}")
	message(STATUS "Found Node.js library: ${NODEJS_LIBRARY}")

	if(NOT NODEJS_INCLUDE_DIR OR NOT NODEJS_LIBRARY)
		message(FATAL_ERROR "Node.js development files not found. Please install nodejs-dev or libnode-dev package.")
	endif()


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

	# Define ENABLE_NODEJS macro for C++ code
	add_compile_definitions(ENABLE_NODEJS)
else()
	message(STATUS "Node.js integration disabled")
endif()

# TODO: Felgo doesnt work on ARM
#find_package(FelgoHotReload REQUIRED)
#target_link_libraries(appCppBackendCharts PRIVATE FelgoHotReload)

set(QT_QML_GENERATE_QMLLS_INI ON)
qt_standard_project_setup()
# Source files - Always include node.h and node.cpp for Qt MOC
# Node thread files are conditional
set(WALLET_SOURCES 
	src/main.cpp
	src/include/node.h
	src/node.cpp
)
if(ENABLE_NODEJS)
	list(APPEND WALLET_SOURCES 
		src/include/node_thread.h
		src/node_thread.cpp
	)
endif()

qt_add_executable(Wallet ${WALLET_SOURCES})

target_include_directories(Wallet PRIVATE src)

# Add Node.js include directories conditionally
if(ENABLE_NODEJS)
	target_include_directories(Wallet PRIVATE ${NODEJS_INCLUDE_DIR})
endif()

# Automatically find all QML files with relative paths
file(GLOB_RECURSE QML_FILES_LIST RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "src/qml/*.qml")

# Find all JavaScript utility files
file(GLOB_RECURSE JS_FILES_LIST RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "src/qml/utils/*.js")

# Find all SVG files in img directory
file(GLOB_RECURSE SVG_FILES_LIST RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "src/img/*.svg")

# Find all JSON translation files
file(GLOB_RECURSE JSON_FILES_LIST RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "src/qml/lang/*.json")

# Add QML module to the executable
qt_add_qml_module(Wallet
	URI WalletModule
	VERSION 1.0
	NO_GENERATE_QMLTYPES
	NO_CACHEGEN
	NO_LINT
	QML_FILES ${QML_FILES_LIST}
	RESOURCES ${SVG_FILES_LIST} ${JSON_FILES_LIST} ${JS_FILES_LIST}
)

# Find Node.js entry files and include all node_modules
file(GLOB_RECURSE NODE_MODULES_FILES_LIST RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "src/js/node_modules/**/*.js")

# Basic Qt libraries
target_link_libraries(Wallet PRIVATE
	Qt6::Core
	Qt6::Quick
	Qt6::Svg
)

# Link Node.js libraries conditionally
if(ENABLE_NODEJS)
	target_link_libraries(Wallet PRIVATE
		${NODEJS_LIBRARY}
		${V8_LIBRARY}
		${V8_LIBBASE_LIBRARY}
		${V8_LIBPLATFORM_LIBRARY}
		${UV_LIBRARY}
	)
endif()

# Link Qt6::Multimedia if available
if(TARGET Qt6::Multimedia)
	target_link_libraries(Wallet PRIVATE Qt6::Multimedia)
	target_compile_definitions(Wallet PRIVATE HAVE_QT_MULTIMEDIA)
	message(STATUS "Qt6Multimedia found - camera support enabled")
else()
	message(WARNING "Qt6Multimedia not found - camera support disabled")
endif()

# Link Qt6::VirtualKeyboard if available
if(TARGET Qt6::VirtualKeyboard)
	target_link_libraries(Wallet PRIVATE Qt6::VirtualKeyboard)
	target_compile_definitions(Wallet PRIVATE HAVE_QT_VIRTUALKEYBOARD)
	message(STATUS "Qt6VirtualKeyboard found - virtual keyboard support enabled")
else()
	message(WARNING "Qt6VirtualKeyboard not found - virtual keyboard support disabled")
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
