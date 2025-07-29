cmake_minimum_required(VERSION 3.16)

project(MainMenuApp VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick)

qt_standard_project_setup()

qt_add_executable(MainMenuApp
 src/main.cpp
 src/include/wifimanager.h
 src/wifimanager.cpp
)

# Add include directories
target_include_directories(MainMenuApp PRIVATE
 src
)

qt_add_qml_module(MainMenuApp
 URI MainMenuAppModule
 VERSION 1.0
 QML_FILES 
  src/qml/main.qml
		src/qml/MainMenu.qml
		src/qml/MenuButton.qml
		src/qml/SettingsPage.qml
		src/qml/SystemSettingsPage.qml
		src/qml/WiFiSettingsPage.qml
)

target_link_libraries(MainMenuApp PRIVATE
 Qt6::Core
 Qt6::Quick
)

# Platform specific settings
if(WIN32)
    set_property(TARGET MainMenuApp PROPERTY WIN32_EXECUTABLE TRUE)
endif()

# Set application properties
set_target_properties(MainMenuApp PROPERTIES
 MACOSX_BUNDLE_GUI_IDENTIFIER com.example.MainMenuApp
 MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
 MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
 MACOSX_BUNDLE TRUE
 WIN32_EXECUTABLE TRUE
)
