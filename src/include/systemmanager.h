#ifndef SYSTEMMANAGER_H
#define SYSTEMMANAGER_H

#include <qqmlintegration.h>

#include <QObject>
#include <QStringList>
#include <QTimer>

class SystemManager : public QObject {
 Q_OBJECT
 QML_ELEMENT

 Q_PROPERTY(int currentWifiStrength READ currentWifiStrength NOTIFY currentWifiStrengthChanged)

public:
 explicit SystemManager(QObject *parent = nullptr);

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
 void currentWifiStrengthChanged();

private slots:
 void checkWifiStatus();

private:
 int m_currentWifiStrength;
 QTimer *m_statusTimer;
};

#endif		// SYSTEMMANAGER_H
