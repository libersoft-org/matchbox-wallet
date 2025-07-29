#ifndef WIFIMANAGER_H
#define WIFIMANAGER_H

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QVariantList>

class WiFiManager : public QObject {
 Q_OBJECT

 Q_PROPERTY(QVariantList networks READ networks NOTIFY networksChanged)
 Q_PROPERTY(bool isScanning READ isScanning NOTIFY isScanningChanged)

public:
 explicit WiFiManager(QObject* parent = nullptr);

 QVariantList networks() const {
		return m_networks;
 }
 bool isScanning() const {
		return m_isScanning;
 }

public slots:
 void scanNetworks();
 void connectToNetwork(const QString& ssid, const QString& password = QString());

signals:
 void networksChanged();
 void isScanningChanged();
 void connectionResult(const QString& ssid, bool success, const QString& error);

private slots:
 void onScanFinished(int exitCode, QProcess::ExitStatus exitStatus);
 void onConnectFinished(int exitCode, QProcess::ExitStatus exitStatus);

private:
 void parseNetworks(const QString& output);
 int signalStrengthToBars(int signalLevel) const;

 QVariantList m_networks;
 bool m_isScanning;
 QProcess* m_scanProcess;
 QProcess* m_connectProcess;
 QString m_connectingSsid;
};

#endif // WIFIMANAGER_H
