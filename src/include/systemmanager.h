#ifndef SYSTEMMANAGER_H
#define SYSTEMMANAGER_H

#include <QObject>
#include <QTimer>
#include <qqmlintegration.h>

class SystemManager : public QObject
{
 Q_OBJECT
 QML_ELEMENT

 Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY batteryLevelChanged)
 Q_PROPERTY(bool hasBattery READ hasBattery NOTIFY hasBatteryChanged)
 Q_PROPERTY(int currentWifiStrength READ currentWifiStrength NOTIFY currentWifiStrengthChanged)

public:
 explicit SystemManager(QObject *parent = nullptr);

 int batteryLevel() const { return m_batteryLevel; }
 bool hasBattery() const { return m_hasBattery; }
 int currentWifiStrength() const { return m_currentWifiStrength; }

public slots:
 void rebootSystem();
 void shutdownSystem();
 void updateSystemStatus();

signals:
 void batteryLevelChanged();
 void hasBatteryChanged();
 void currentWifiStrengthChanged();

private slots:
 void checkBatteryStatus();
 void checkWifiStatus();

private:
 int m_batteryLevel;
 bool m_hasBattery;
 int m_currentWifiStrength;
 QTimer *m_statusTimer;
};

#endif // SYSTEMMANAGER_H
