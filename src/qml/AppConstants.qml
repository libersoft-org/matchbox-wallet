pragma Singleton
import QtQuick 2.15

QtObject {
	readonly property string fontFamily: "Droid Sans"
	readonly property color primaryBackground: "#222"
	readonly property color primaryForeground: "#fd3"
	readonly property color disabledBackground: "#aaa"
	readonly property color disabledForeground: "#444"
	readonly property int defaultMargin: 20
	readonly property int defaultSpacing: 15
}
