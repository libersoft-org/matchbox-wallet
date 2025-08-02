import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import WalletModule 1.0
import "../../components"

Rectangle {
	id: root
	color: AppConstants.primaryBackground
	
	signal backRequested
	signal currencySelectionRequested
	
	property string selectedCurrency: "USD"
	
	ColumnLayout {
		anchors.fill: parent
		anchors.margins: root.width * 0.05
		spacing: root.height * 0.03
		
		// Title area - 10% výšky
		Item {
			Layout.fillWidth: true
			Layout.preferredHeight: root.height * 0.1
			
			Text {
				anchors.centerIn: parent
				text: qsTr("General Settings")
				font.pixelSize: parent.height * 0.5
				font.bold: true
				color: AppConstants.primaryForeground
			}
		}
		
		// Settings content area - zbytek výšky
		Item {
			Layout.fillWidth: true
			Layout.fillHeight: true
			
			ColumnLayout {
				anchors.centerIn: parent
				width: parent.width - (parent.width * 0.1)
				spacing: root.height * 0.02
				
				// Fiat currency selection
				RowLayout {
					Layout.fillWidth: true
					Layout.preferredHeight: root.height * 0.08
					
					Text {
						text: qsTr("Fiat currency:")
						font.pixelSize: 18
						font.bold: true
						color: AppConstants.primaryForeground
						Layout.preferredWidth: parent.width * 0.4
					}
					
					MenuButton {
						Layout.fillWidth: true
						text: root.selectedCurrency
						onClicked: {
							root.currencySelectionRequested();
						}
					}
				}
				
				// Spacer
				Item {
					Layout.fillHeight: true
				}
				
				// Back button
				MenuButton {
					Layout.fillWidth: true
					text: qsTr("← Back")
					onClicked: {
						root.backRequested();
					}
				}
			}
		}
	}
}
