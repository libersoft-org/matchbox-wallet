pragma ComponentBehavior: Bound
import QtQuick 2.15
import Qt.labs.folderlistmodel 2.15
import "../../components"

Item {
	id: root
	property string title: tr("menu.player.local")
	property var goPageFunction
	property var playerVideoComponent
	property string currentPath: "/root"
	property var pathHistory: []

	FolderListModel {
		id: folderModel
		folder: "file://" + root.currentPath
		//nameFilters: ["*.mp4", "*.avi", "*.mkv", "*.mov", "*.wmv", "*.flv", "*.webm", "*.m4v"]
		showDirs: true
		showFiles: true
		showDotAndDotDot: false
		showOnlyReadable: true
	}

	BaseMenu {
		id: menu
		title: tr("menu.player.local")
		anchors.fill: parent

		// Current path display
		Text {
			text: root.currentPath
			font.pixelSize: window.width * 0.05
			color: colors.primaryForeground
			enabled: false
		}

		// Back to parent directory button (shown when not in root)
		MenuButton {
			visible: root.currentPath !== "/root"
			text: "⬆️ " + tr("menu.player.back")
			onClicked: {
				if (root.pathHistory.length > 0) {
					root.currentPath = root.pathHistory.pop();
				} else {
					// Go to parent directory
					var parentPath = root.currentPath.substring(0, root.currentPath.lastIndexOf("/"));
					if (parentPath === "")
						parentPath = "/";
					root.currentPath = parentPath;
				}
			}
		}

		// Directory and file entries
		Repeater {
			model: folderModel

			MenuButton {
				required property bool fileIsDir
				required property string fileName
				required property url fileURL
				property bool isDirectory: fileIsDir
				property string filePath: fileURL.toString().replace("file://", "")
				backgroundColor: isDirectory ? colors.success : colors.primaryForeground
				text: fileName

				onClicked: {
					if (isDirectory) {
						// Navigate to directory
						var newHistory = root.pathHistory.slice();
						newHistory.push(root.currentPath);
						root.pathHistory = newHistory;
						root.currentPath = filePath;
					} else {
						// Play video file
						console.log("Opening local video file:", filePath);
						if (root.goPageFunction) {
							var component = Qt.createComponent("PlayerVideo.qml");
							if (component.status === Component.Ready) {
								var videoPage = component.createObject(null, {
									"sourceUrl": "file://" + filePath
								});
								if (videoPage) {
									console.log("Local video component created successfully");
									root.goPageFunction(videoPage);
								} else {
									console.error("Failed to create local video page object");
								}
							} else {
								console.error("Failed to create component:", component.errorString());
							}
						}
					}
				}
			}
		}
	}
}
