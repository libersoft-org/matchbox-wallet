import QtQuick 6.4

// Singleton that provides app context with fallbacks for Felgo Hot Reload
pragma Singleton

QtObject {
    // Use injected context properties if available, otherwise fallback values
    readonly property var nodeJS: (typeof NodeJS !== 'undefined') ? NodeJS : null
    readonly property string applicationName: (typeof applicationName !== 'undefined') ? applicationName : "Matchbox Wallet (Dev)"
    readonly property string applicationVersion: (typeof applicationVersion !== 'undefined') ? applicationVersion : "0.0.1-dev"
    readonly property int wifiStrengthUpdateInterval: (typeof wifiStrengthUpdateInterval !== 'undefined') ? wifiStrengthUpdateInterval : 5000
    readonly property int batteryStatusUpdateInterval: (typeof batteryStatusUpdateInterval !== 'undefined') ? batteryStatusUpdateInterval : 10000  
    readonly property int eventsPollInterval: (typeof eventsPollInterval !== 'undefined') ? eventsPollInterval : 3500
    
    // Indicate if we're running in hot reload mode (missing context properties)
    readonly property bool isHotReloadMode: typeof NodeJS === 'undefined'
    
    Component.onCompleted: {
        if (isHotReloadMode) {
            console.log("AppContext: Running in Hot Reload mode with fallback values")
        } else {
            console.log("AppContext: Running with injected context properties")
        }
    }
}