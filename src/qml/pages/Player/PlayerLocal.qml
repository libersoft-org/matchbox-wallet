pragma ComponentBehavior: Bound
import QtQuick 6.8
import QtCore
import Qt.labs.folderlistmodel 6.8
import "../../components"

Item {
	id: root
	property string title: tr("player.local")
	property string currentPath: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
	property var pathHistory: []

	Component.onCompleted: {
		// Ensure we start in the home directory
		var homeLocation = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0];
		console.log("PlayerLocal: Initializing with home directory:", homeLocation);
		root.currentPath = homeLocation;
		folderModel.folder = "file://" + homeLocation;
	}

	FolderListModel {
		id: folderModel
		folder: "file://" + StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
		//nameFilters: ["*.mp4", "*.avi", "*.mkv", "*.mov", "*.wmv", "*.flv", "*.webm", "*.m4v"]
		showDirs: true
		showFiles: true
		showDotAndDotDot: false
		showOnlyReadable: true
		sortField: FolderListModel.Name
		onFolderChanged: console.log("FolderListModel: folder changed to:", folder)
		onCountChanged: {
			console.log("FolderListModel: count changed to:", count);
			for (var i = 0; i < count; i++) {
				console.log("  File", i + ":", get(i, "fileName"), "isDir:", get(i, "fileIsDir"));
			}
		}
	}

	// Watch for path changes and update folder model
	onCurrentPathChanged: {
		console.log("Current path changed to:", currentPath);
		folderModel.folder = "file://" + currentPath;
	}

	BaseMenu {
		id: menu
		title: tr("player.local")
		anchors.fill: parent

		// Current path display
		Text {
			text: root.currentPath.replace("file://", "")
			font.pixelSize: window.width * 0.05
			font.bold: true
			color: colors.primaryForeground
		}

		MenuButton {
			property string cleanCurrentPath: root.currentPath.toString().replace("file://", "")
			property string homeLocation: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0].toString().replace("file://", "")
			visible: cleanCurrentPath !== homeLocation
			text: tr("player.back")
			backgroundColor: colors.success
			onClicked: {
				var homeLocation = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0];
				if (root.pathHistory.length > 0) {
					var previousPath = root.pathHistory.pop();
					// Only go back if the previous path is within home directory
					if (previousPath.startsWith(homeLocation))
						root.currentPath = previousPath;
					else
						root.currentPath = homeLocation;
				} else {
					// Go to parent directory, but not above home
					var parentPath = root.currentPath.substring(0, root.currentPath.lastIndexOf("/"));
					if (parentPath === "" || !parentPath.startsWith(homeLocation))
						parentPath = homeLocation;
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
						window.goPage('Player/PlayerVideo.qml', null, {
							"sourceUrl": "file://" + filePath
						});
					}
				}
			}
		}
	}
}
