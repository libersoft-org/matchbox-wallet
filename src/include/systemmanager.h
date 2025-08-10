#ifndef SYSTEMMANAGER_H
#define SYSTEMMANAGER_H

#include <qqmlintegration.h>

#include <QObject>
#include <QTimer>
#include <QStringList>

class SystemManager : public QObject {
 Q_OBJECT
 QML_ELEMENT

 Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY batteryLevelChanged)
 Q_PROPERTY(bool hasBattery READ hasBattery NOTIFY hasBatteryChanged)
 Q_PROPERTY(bool charging READ charging NOTIFY chargingChanged)
 Q_PROPERTY(int currentWifiStrength READ currentWifiStrength NOTIFY currentWifiStrengthChanged)

public:
 explicit SystemManager(QObject *parent = nullptr);

 int batteryLevel() const {
		return m_batteryLevel;
 }
 bool hasBattery() const {
		return m_hasBattery;
 }
 bool charging() const {
		return m_isCharging;
 }
 int currentWifiStrength() const {
		return m_currentWifiStrength;
 }

public slots:
 void rebootSystem();
 void shutdownSystem();
 void updateSystemStatus();
 void syncSystemTime();
 void setAutoTimeSync(bool enabled);
 void setTimeZone(const QString &tz);
 void setNtpServer(const QString &server);

 // QML-callable helpers
 Q_INVOKABLE QStringList listTimeZones() const;

signals:
 void batteryLevelChanged();
 void hasBatteryChanged();
 void chargingChanged();
 void currentWifiStrengthChanged();

private slots:
 void checkBatteryStatus();
 void checkWifiStatus();

private:
 int m_batteryLevel;
 bool m_hasBattery;
 bool m_isCharging;
 int m_currentWifiStrength;
 QTimer *m_statusTimer;
};

#endif		// SYSTEMMANAGER_H
