cmake_minimum_required(VERSION 3.16)
project(Wallet VERSION 1.0.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Option to enable/disable Node.js integration
option(ENABLE_NODEJS "Enable Node.js integration" ON)

# Option to enable/disable Felgo Live integration
option(ENABLE_FELGO_LIVE "Enable Felgo Live for hot reload" OFF)

# Option to enable hot reload with filesystem loading (disables QRC bundling)
option(ENABLE_HOT_RELOAD "Enable hot reload with filesystem sources" OFF)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Svg)
find_package(Qt6 QUIET COMPONENTS Multimedia VirtualKeyboard)

# Felgo Live integration (conditional)
if(ENABLE_FELGO_LIVE)
  # Try to find Felgo SDK components
  find_package(Felgo QUIET)
  find_package(FelgoHotReload QUIET)
  
  if(Felgo_FOUND AND FelgoHotReload_FOUND)
    message(STATUS "Felgo Live support enabled")
    add_compile_definitions(ENABLE_FELGO_LIVE)
  else()
    message(WARNING "Felgo Live requested but Felgo SDK not found. Install Felgo SDK or disable ENABLE_FELGO_LIVE")
    if(NOT Felgo_FOUND)
      message(WARNING "  - Felgo core not found")
    endif()
    if(NOT FelgoHotReload_FOUND)
      message(WARNING "  - FelgoHotReload not found")
    endif()
  endif()
else()
  message(STATUS "Felgo Live support disabled")
endif()







# Node.js integration (conditional)
if(ENABLE_NODEJS)

  # ---- Toggle verbose logs for this block
  option(NODEJS_LOG "Verbose Node.js find logging" ON)

  function(_node_log msg)
    if(NODEJS_LOG)
      message(STATUS "[NODEJS] ${msg}")
    endif()
  endfunction()

  macro(_node_log_var varname)
    if(NODEJS_LOG)
      if(DEFINED ${varname})
        # Show lists nicely too
        if(${varname})
          string(REPLACE ";" ", " __v "${${varname}}")
          message(STATUS "[NODEJS] ${varname} = ${__v}")
        else()
          message(STATUS "[NODEJS] ${varname} = (empty)")
        endif()
      else()
        message(STATUS "[NODEJS] ${varname} = (undefined)")
      endif()
    endif()
  endmacro()

  include(GNUInstallDirs)

  _node_log("---- Environment & toolchain ----")
  _node_log_var(CMAKE_SYSTEM_NAME)
  _node_log_var(CMAKE_SYSTEM_PROCESSOR)
  _node_log_var(CMAKE_LIBRARY_ARCHITECTURE)
  _node_log_var(CMAKE_C_COMPILER)
  _node_log_var(CMAKE_CXX_COMPILER)
  _node_log_var(CMAKE_SYSROOT)
  _node_log_var(CMAKE_PREFIX_PATH)
  _node_log_var(CMAKE_FIND_ROOT_PATH)
  _node_log_var(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM)
  _node_log_var(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY)
  _node_log_var(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE)
  _node_log_var(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE)

  # ---- Header search
  set(_NODE_INCLUDE_BASES
    /usr/include
    /usr/local/include
    /opt/homebrew/include
  )
  set(_NODE_INCLUDE_SUFFIXES node nodejs)

  _node_log("---- Header search config ----")
  _node_log_var(_NODE_INCLUDE_BASES)
  _node_log_var(_NODE_INCLUDE_SUFFIXES)

  find_path(NODEJS_INCLUDE_DIR
    NAMES node.h
    PATHS ${_NODE_INCLUDE_BASES}
    PATH_SUFFIXES ${_NODE_INCLUDE_SUFFIXES}
  )

  _node_log_var(NODEJS_INCLUDE_DIR)

  if(NODEJS_INCLUDE_DIR)
    set(_candidate_header "${NODEJS_INCLUDE_DIR}/node.h")
    if(EXISTS "${_candidate_header}")
      _node_log("Found header file: ${_candidate_header}")
    else()
      _node_log("WARNING: include dir found but node.h missing at ${_candidate_header}")
      file(GLOB __ls "${NODEJS_INCLUDE_DIR}/*")
      if(__ls)
        string(REPLACE ";" ", " __ls_print "${__ls}")
        _node_log("Contents of ${NODEJS_INCLUDE_DIR}: ${__ls_print}")
      endif()
    endif()
  endif()

  # ---- Library search
  set(_ARCH_SUFFIX_CANDIDATES
    ${CMAKE_LIBRARY_ARCHITECTURE}
    aarch64-linux-gnu
    arm64
    x86_64-linux-gnu
  )

  _node_log("---- Library search config ----")
  _node_log_var(_ARCH_SUFFIX_CANDIDATES)

  find_library(NODEJS_LIBRARY
    NAMES node libnode
    PATHS /usr/lib /usr/local/lib /opt/homebrew/lib
    PATH_SUFFIXES ${_ARCH_SUFFIX_CANDIDATES}
  )

  _node_log_var(NODEJS_LIBRARY)

  if(NODEJS_LIBRARY)
    get_filename_component(_NODELIB_REAL "${NODEJS_LIBRARY}" REALPATH)
    _node_log("libnode resolved realpath: ${_NODELIB_REAL}")
  else()
    foreach(_sfx IN LISTS _ARCH_SUFFIX_CANDIDATES)
      set(_probe "/usr/lib/${_sfx}/libnode.so")
      if(EXISTS "${_probe}")
        _node_log("NOTE: libnode exists at ${_probe} but find_library did not pick it up")
      endif()
    endforeach()
  endif()

  # ---- Final check
  if(NOT NODEJS_INCLUDE_DIR OR NOT NODEJS_LIBRARY)
    _node_log("FAIL: Node.js development files not found with the above settings.")
    message(FATAL_ERROR "Node.js development files not found. Please install libnode-dev for the target arch or fix search paths.")
  endif()

  # ---- Optional extras (V8/libuv) with logging
  foreach(_pair
      "V8_LIBRARY;v8;libv8"
      "V8_LIBBASE_LIBRARY;v8_libbase;libv8_libbase"
      "V8_LIBPLATFORM_LIBRARY;v8_libplatform;libv8_libplatform"
      "UV_LIBRARY;uv;libuv")
    list(GET _pair 0 _var)
    list(GET _pair 1 _n1)
    list(GET _pair 2 _n2)
    find_library(${_var}
      NAMES ${_n1} ${_n2}
      PATHS /usr/lib /usr/local/lib /opt/homebrew/lib
      PATH_SUFFIXES ${_ARCH_SUFFIX_CANDIDATES}
    )
    _node_log_var(${_var})
  endforeach()

  add_compile_definitions(ENABLE_NODEJS)

else()
  message(STATUS "Node.js integration disabled")
endif()










# Felgo integration is now handled conditionally above

set(QT_QML_GENERATE_QMLLS_INI ON)
qt_standard_project_setup()
# Source files - Always include node.h and node.cpp for Qt MOC
# Node thread files are conditional
set(WALLET_SOURCES 
	src/main.cpp
	src/include/node.h
	src/node.cpp
	src/include/hotreload.h
	src/hotreload.cpp
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
if(ENABLE_HOT_RELOAD)
	# Hot reload mode: don't bundle QML files into QRC, use filesystem with symlinks
	message(STATUS "Hot reload enabled - QML files will be loaded from filesystem via symlinks")
	qt_add_qml_module(Wallet
		URI WalletModule
		VERSION 1.0
		NO_GENERATE_QMLTYPES
		NO_CACHEGEN
		NO_LINT
		RESOURCES ${SVG_FILES_LIST} ${JSON_FILES_LIST} ${JS_FILES_LIST}
		# QML_FILES intentionally omitted - no QRC bundling
	)
	
	# Create symlinks for individual QML files to preserve module structure
	foreach(qml_file ${QML_FILES_LIST})
		get_filename_component(qml_dir ${qml_file} DIRECTORY)
		file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/WalletModule/${qml_dir})
		
		set(source_file ${CMAKE_SOURCE_DIR}/${qml_file})
		set(target_file ${CMAKE_BINARY_DIR}/WalletModule/${qml_file})
		
		# Create symlink at configure time
		if(NOT EXISTS ${target_file})
			execute_process(
				COMMAND ${CMAKE_COMMAND} -E create_symlink ${source_file} ${target_file}
				RESULT_VARIABLE symlink_result
			)
			if(symlink_result EQUAL 0)
				message(STATUS "Symlinked: ${qml_file}")
			else()
				message(WARNING "Failed to symlink ${qml_file}")
			endif()
		endif()
	endforeach()
	
	add_compile_definitions(ENABLE_HOT_RELOAD)
else()
	# Production mode: bundle QML files into QRC as usual
	message(STATUS "Production mode - QML files bundled into QRC")
	qt_add_qml_module(Wallet
		URI WalletModule
		VERSION 1.0
		NO_GENERATE_QMLTYPES
		NO_CACHEGEN
		NO_LINT
		QML_FILES ${QML_FILES_LIST}
		RESOURCES ${SVG_FILES_LIST} ${JSON_FILES_LIST} ${JS_FILES_LIST}
	)
endif()

# Add Qt resource file for JavaScript files
qt_add_resources(Wallet "js_resources"
	PREFIX "/js"
	FILES
		js/bootstrap.js
		js/dist/bundle.cjs
)

# Find Node.js entry files and include all node_modules
file(GLOB_RECURSE NODE_MODULES_FILES_LIST RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "js/node_modules/**/*.js")

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

# Link Felgo libraries conditionally
if(ENABLE_FELGO_LIVE)
  if(Felgo_FOUND AND FelgoHotReload_FOUND)
    target_link_libraries(Wallet PRIVATE Felgo FelgoHotReload)
  endif()
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
