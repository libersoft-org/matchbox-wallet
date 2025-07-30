cmake_minimum_required(VERSION 3.16)

project(Wallet VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick)

qt_standard_project_setup()

qt_add_executable(Wallet
 src/main.cpp
 src/include/wifimanager.h
 src/wifimanager.cpp
)

# Add include directories
target_include_directories(Wallet PRIVATE
 src
)

qt_add_qml_module(Wallet
 URI WalletModule
 VERSION 1.0
 NO_GENERATE_QMLTYPES
 NO_CACHEGEN
 NO_LINT
 QML_FILES 
  src/qml/main.qml
		src/qml/MainMenu.qml
		src/qml/MenuButton.qml
		src/qml/SettingsPage.qml
		src/qml/SystemSettingsPage.qml
		src/qml/WiFiSettingsPage.qml
)

target_link_libraries(Wallet PRIVATE
 Qt6::Core
 Qt6::Quick
)

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
