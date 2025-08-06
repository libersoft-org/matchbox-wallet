#include "include/wifimanager.h"

#include <QDebug>
#include <QRegularExpression>
#include <QVariantMap>

WiFiManager::WiFiManager(QObject* parent) : QObject(parent), m_isScanning(false), m_scanProcess(nullptr), m_connectProcess(nullptr) {}

void WiFiManager::scanNetworks() {
 if (m_isScanning) {
		return;
 }

 m_isScanning = true;
 emit isScanningChanged();

 // Clear previous networks
 m_networks.clear();
 emit networksChanged();

 // First trigger a rescan
 QProcess* rescanProcess = new QProcess(this);
 rescanProcess->start("nmcli", QStringList() << "device"
																																													<< "wifi"
																																													<< "rescan");

 // Wait a bit for rescan to complete, then get the list
 QTimer::singleShot(2000, this, [this]() {
		if (m_scanProcess) {
			m_scanProcess->kill();
			m_scanProcess->deleteLater();
		}

		m_scanProcess = new QProcess(this);
		connect(m_scanProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &WiFiManager::onScanFinished);

		// Get WiFi list with specific fields
		QStringList args;
		args << "-t"
							<< "-f"
							<< "SSID,SIGNAL,SECURITY,ACTIVE"
							<< "device"
							<< "wifi"
							<< "list";
		m_scanProcess->start("nmcli", args);
 });
}

void WiFiManager::onScanFinished(int exitCode, QProcess::ExitStatus exitStatus) {
 Q_UNUSED(exitStatus)

 m_isScanning = false;
 emit isScanningChanged();

 if (exitCode == 0) {
		QString output = m_scanProcess->readAllStandardOutput();
		parseNetworks(output);
 } else {
		qDebug() << "WiFi scan failed:" << m_scanProcess->readAllStandardError();
		// Provide some fallback data
		QVariantMap network;
		network["name"] = "No networks found";
		network["strength"] = 0;
		network["secured"] = false;
		network["connected"] = false;
		m_networks.append(network);
		emit networksChanged();
 }

 m_scanProcess->deleteLater();
 m_scanProcess = nullptr;
}

void WiFiManager::parseNetworks(const QString& output) {
 QStringList lines = output.split('\n', Qt::SkipEmptyParts);
 QStringList seenNetworks;

 for (const QString& line : lines) {
		QStringList parts = line.split(':');
		if (parts.size() >= 4) {
			QString ssid = parts[0].trimmed();
			QString signalStr = parts[1].trimmed();
			QString security = parts[2].trimmed();
			QString active = parts[3].trimmed();

			// Skip empty SSIDs and duplicates
			if (ssid.isEmpty() || ssid == "--" || seenNetworks.contains(ssid)) {
				continue;
			}

			seenNetworks.append(ssid);

			QVariantMap network;
			network["name"] = ssid;
			network["strength"] = signalStrengthToBars(signalStr.toInt());
			network["secured"] = !security.isEmpty() && security != "--";
			network["connected"] = (active == "yes");

			m_networks.append(network);
		}
 }

 // Sort by signal strength (strongest first)
 std::sort(m_networks.begin(), m_networks.end(), [](const QVariant& a, const QVariant& b) { return a.toMap()["strength"].toInt() > b.toMap()["strength"].toInt(); });

 emit networksChanged();
}

int WiFiManager::signalStrengthToBars(int signalLevel) const {
 // Convert signal percentage to bars (1-4)
 if (signalLevel >= 75) return 4;
 if (signalLevel >= 50) return 3;
 if (signalLevel >= 25) return 2;
 return 1;
}

void WiFiManager::connectToNetwork(const QString& ssid, const QString& password) {
 if (m_connectProcess && m_connectProcess->state() != QProcess::NotRunning) {
		return;
 }

 m_connectingSsid = ssid;

 if (m_connectProcess) {
		m_connectProcess->deleteLater();
 }

 m_connectProcess = new QProcess(this);
 connect(m_connectProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &WiFiManager::onConnectFinished);

 QStringList args;
 args << "device"
						<< "wifi"
						<< "connect" << ssid;

 if (!password.isEmpty()) {
		args << "password" << password;
 }

 qDebug() << "Connecting to" << ssid << "with nmcli";
 m_connectProcess->start("nmcli", args);
}

void WiFiManager::onConnectFinished(int exitCode, QProcess::ExitStatus exitStatus) {
 Q_UNUSED(exitStatus)

 bool success = (exitCode == 0);
 QString error;

 if (!success) {
		error = m_connectProcess->readAllStandardError();
		qDebug() << "Connection failed:" << error;
 } else {
		qDebug() << "Successfully connected to" << m_connectingSsid;
		// Refresh networks to show new connection status
		QTimer::singleShot(1000, this, &WiFiManager::scanNetworks);
 }

 emit connectionResult(m_connectingSsid, success, error);

 m_connectProcess->deleteLater();
 m_connectProcess = nullptr;
 m_connectingSsid.clear();
}
