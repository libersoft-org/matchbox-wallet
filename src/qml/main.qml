import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import WalletModule 1.0
import "components"
import "pages"
import "pages/Settings"

ApplicationWindow {
 id: window
 width: 480
 height: 640
 visible: true
 title: qsTr("Matchbox Wallet")
 font.family: AppConstants.fontFamily
 
 // Set window icon
 property string iconSource: "qrc:/WalletModule/src/img/wallet.svg"
 
 background: Rectangle {
  color: AppConstants.primaryBackground
 }

 Component.onCompleted: {
  x = (Screen.width - width) / 2;
  y = (Screen.height - height) / 2;
 }

 function goPage(component) {
  if (stackView && component) stackView.push(component);
 }

 function goBack() {
  stackView.pop();
 }

 // Animation constants
 readonly property int animationDuration: 500
 readonly property var animationEasing: Easing.OutCubic

 // Fixed navigation bar at top
 NavigationBar {
  id: fixedNavigationBar
  anchors.top: parent.top
  anchors.left: parent.left
  anchors.right: parent.right
  height: window.height * 0.1
  title: stackView.currentItem ? stackView.currentItem.title || "" : ""
  showBackButton: stackView.depth > 1
  showPowerButton: true
  onBackRequested: window.goBack()
  onPowerOffRequested: window.goPage(powerOffPageComponent)
 }

 // Content area with animations - only this part animates
 StackView {
  id: stackView
  anchors.top: fixedNavigationBar.bottom
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.bottom: parent.bottom
  initialItem: mainMenuComponent
  
  pushEnter: Transition {
   PropertyAnimation {
    property: "x"
    from: stackView.width
    to: 0
    duration: window.animationDuration
    easing.type: window.animationEasing
   }
  }
  
  pushExit: Transition {
   PropertyAnimation {
    property: "x"
    from: 0
    to: -stackView.width
    duration: window.animationDuration
    easing.type: window.animationEasing
   }
  }
  
  popEnter: Transition {
   PropertyAnimation {
    property: "x"
    from: -stackView.width
    to: 0
    duration: window.animationDuration
    easing.type: window.animationEasing
   }
  }
  
  popExit: Transition {
   PropertyAnimation {
    property: "x"
    from: 0
    to: stackView.width
    duration: window.animationDuration
    easing.type: window.animationEasing
   }
  }
 }

 Component {
  id: mainMenuComponent
  Item {
   property string title: qsTr("Matchbox Wallet")
   
   MenuContainer {
    anchors.fill: parent
    anchors.leftMargin: parent.width * 0.05
    anchors.rightMargin: parent.width * 0.05
    anchors.topMargin: parent.height * 0.03
    
    MenuButton {
     text: qsTr("Settings")
     onClicked: window.goPage(settingsPageComponent)
    }

    MenuButton {
     text: qsTr("Test camera")
     onClicked: window.goPage(cameraPreviewPageComponent)
    }

    MenuButton {
     text: qsTr("Disabled button")
     backgroundColor: "#00f"
     textColor: "#fff"
     enabled: false
    }
   }
  }
 }

 Component {
  id: settingsPageComponent
  Item {
   property string title: qsTr("Settings")
   
   MenuContainer {
    anchors.fill: parent
    anchors.leftMargin: parent.width * 0.05
    anchors.rightMargin: parent.width * 0.05
    anchors.topMargin: parent.height * 0.03
    
    MenuButton {
     text: qsTr("General")
     onClicked: window.goPage(generalSettingsPageComponent)
    }

    MenuButton {
     text: qsTr("System")
     onClicked: window.goPage(systemSettingsPageComponent)
    }

    MenuButton {
     text: qsTr("Back")
     onClicked: window.goBack()
    }
   }
  }
 }

 // General settings page
 Component {
  id: generalSettingsPageComponent
  Item {
   property string title: qsTr("General Settings")
   property string selectedCurrency: "USD"
   
   MenuContainer {
    anchors.fill: parent
    anchors.leftMargin: parent.width * 0.05
    anchors.rightMargin: parent.width * 0.05
    anchors.topMargin: parent.height * 0.03
    
    MenuButton {
     text: qsTr("Fiat Currency: %1").arg(parent.parent.selectedCurrency)
     onClicked: window.goPage(settingsGeneralFiatPageComponent)
    }
   }
  }
 }

 // Currency selection page
 Component {
  id: settingsGeneralFiatPageComponent
  Item {
   property string title: qsTr("Select Currency")
   property var currencies: ["USD", "EUR", "GBP", "CHF", "CZK", "PLN", "HUF"]
   
   MenuContainer {
    anchors.fill: parent
    anchors.leftMargin: parent.width * 0.05
    anchors.rightMargin: parent.width * 0.05
    anchors.topMargin: parent.height * 0.03
    
    Repeater {
     model: parent.parent.currencies
     
     MenuButton {
      text: modelData
      onClicked: {
       console.log("Currency selected:", modelData);
       window.goBack();
      }
     }
    }

    MenuButton {
     text: qsTr("Back")
     onClicked: window.goBack()
    }
   }
  }
 }

 // System settings page
 Component {
  id: systemSettingsPageComponent
  Item {
   property string title: qsTr("System Settings")
   
   MenuContainer {
    anchors.fill: parent
    anchors.leftMargin: parent.width * 0.05
    anchors.rightMargin: parent.width * 0.05
    anchors.topMargin: parent.height * 0.03
    
    MenuButton {
     text: qsTr("WiFi")
     onClicked: window.goPage(wifiSettingsPageComponent)
    }

    MenuButton {
     text: qsTr("LoRa")
     enabled: false
     onClicked: console.log("LoRa settings clicked - not implemented yet")
    }
   }
  }
 }

 // WiFi settings page
 Component {
  id: wifiSettingsPageComponent
  Item {
   property string title: qsTr("WiFi Networks")
   
   SettingsSystemWiFi {
    anchors.fill: parent
    onBackRequested: window.goBack()
    onPowerOffRequested: window.goPage(powerOffPageComponent)
   }
  }
 }

 // Power off page
 Component {
  id: powerOffPageComponent
  Item {
   property string title: qsTr("Power options")
   property SystemManager systemManager: SystemManager { }
   
   MenuContainer {
    anchors.fill: parent
    anchors.leftMargin: parent.width * 0.05
    anchors.rightMargin: parent.width * 0.05
    anchors.topMargin: parent.height * 0.03
    
    MenuButton {
     text: qsTr("Exit application")
     onClicked: Qt.quit()
    }

    MenuButton {
     text: qsTr("Reboot")
     onClicked: parent.parent.systemManager.rebootSystem()
    }

    MenuButton {
     text: qsTr("Power off")
     onClicked: parent.parent.systemManager.shutdownSystem()
    }
   }
  }
 }

 // Camera preview page
 Component {
  id: cameraPreviewPageComponent
  Item {
   property string title: qsTr("Camera Preview")
   
   CameraPreview {
    anchors.fill: parent
    onBackRequested: {
     // Stop camera before going back
     window.goBack()
    }
    onPowerOffRequested: window.goPage(powerOffPageComponent)
   }
  }
 }
}
