#include "include/systemmanager.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QTextStream>
#ifdef Q_OS_UNIX
#include <unistd.h>  // for getuid()
#endif

SystemManager::SystemManager(QObject *parent) : QObject(parent), m_batteryLevel(100), m_hasBattery(true), m_isCharging(false), m_currentWifiStrength(0) {
 // Timer for periodic status updates
 m_statusTimer = new QTimer(this);
 connect(m_statusTimer, &QTimer::timeout, this, &SystemManager::updateSystemStatus);
 m_statusTimer->start(5000);  // Update every 5 seconds

 // Initial status check
 updateSystemStatus();
}

void SystemManager::updateSystemStatus() {
 checkBatteryStatus();
 checkWifiStatus();
}

void SystemManager::checkBatteryStatus() {
 // Check if battery exists
 QDir batteryDir("/sys/class/power_supply");
 QStringList batteries = batteryDir.entryList(QStringList() << "BAT*", QDir::Dirs);

 if (batteries.isEmpty()) {
  // No battery found
  if (m_hasBattery) {
   m_hasBattery = false;
   emit hasBatteryChanged();
  }
  if (m_isCharging) {
   m_isCharging = false;
   emit chargingChanged();
  }
  return;
 }

 // Battery found
 if (!m_hasBattery) {
  m_hasBattery = true;
  emit hasBatteryChanged();
 }

 // Read battery level from first available battery
 QString batteryPath = "/sys/class/power_supply/" + batteries.first();
 QFile capacityFile(batteryPath + "/capacity");
 QFile statusFile(batteryPath + "/status");

 if (capacityFile.open(QIODevice::ReadOnly)) {
  QTextStream in(&capacityFile);
  QString capacityStr = in.readLine().trimmed();
  bool ok;
  int newLevel = capacityStr.toInt(&ok);
  if (ok && newLevel != m_batteryLevel) {
   m_batteryLevel = qBound(0, newLevel, 100);
   emit batteryLevelChanged();
  }
 } else {
  // Fallback: try to use upower if available
  QProcess process;
  process.start("upower", QStringList() << "-i" << "/org/freedesktop/UPower/devices/battery_BAT0");
  process.waitForFinished(2000);

  if (process.exitCode() == 0) {
   QString output = process.readAllStandardOutput();
   QStringList lines = output.split('\n');

   for (const QString &line : lines) {
    if (line.contains("percentage")) {
     QString percentStr = line.split(':').last().trimmed();
     percentStr = percentStr.remove('%');
     bool ok;
     int newLevel = percentStr.toInt(&ok);
     if (ok && newLevel != m_batteryLevel) {
      m_batteryLevel = qBound(0, newLevel, 100);
      emit batteryLevelChanged();
     }
     break;
    }
   if (line.contains("state")) {
    QString stateStr = line.split(':').last().trimmed();
    bool nowCharging = stateStr.contains("charging", Qt::CaseInsensitive) || stateStr.contains("unknown", Qt::CaseInsensitive);
    if (nowCharging != m_isCharging) {
     m_isCharging = nowCharging;
     emit chargingChanged();
    }
   }
   }
  }

 // Prefer sysfs status if available
 if (statusFile.open(QIODevice::ReadOnly)) {
  QTextStream in(&statusFile);
  QString statusStr = in.readLine().trimmed();
  bool nowCharging = statusStr.compare("Charging", Qt::CaseInsensitive) == 0
                  || statusStr.compare("Full", Qt::CaseInsensitive) == 0
                  || statusStr.compare("Unknown", Qt::CaseInsensitive) == 0; // treat unknown as charging for icon
  if (nowCharging != m_isCharging) {
   m_isCharging = nowCharging;
   emit chargingChanged();
  }
 }
 }
}

void SystemManager::checkWifiStatus() {
 // First check if we have an active WiFi connection
 QProcess connectionProcess;
 connectionProcess.start("nmcli", QStringList() << "-t" << "-f" << "TYPE,STATE" << "connection" << "show" << "--active");
 connectionProcess.waitForFinished(2000);

 bool hasActiveWifi = false;
 if (connectionProcess.exitCode() == 0) {
  QString output = connectionProcess.readAllStandardOutput();
  QStringList lines = output.split('\n', Qt::SkipEmptyParts);

  for (const QString &line : lines) {
   QStringList parts = line.split(':');
   if (parts.size() >= 2 && parts[0].contains("802-11-wireless") && parts[1].contains("activated")) {
    hasActiveWifi = true;
    break;
   }
  }
 }

 int newStrength = 0;

 if (hasActiveWifi) {
  // Get signal strength of active connection
  QProcess signalProcess;
  signalProcess.start("nmcli", QStringList() << "-t" << "-f" << "SIGNAL" << "device" << "wifi" << "list" << "--rescan" << "no");
  signalProcess.waitForFinished(3000);

  if (signalProcess.exitCode() == 0) {
   QString output = signalProcess.readAllStandardOutput();
   QStringList lines = output.split('\n', Qt::SkipEmptyParts);

   int maxSignal = 0;
   for (const QString &line : lines) {
    bool ok;
    int signal = line.trimmed().toInt(&ok);
    if (ok && signal > maxSignal) {
     maxSignal = signal;
    }
   }

   // Convert signal percentage to bars (1-4) only if connected
   if (maxSignal >= 75)
    newStrength = 4;
   else if (maxSignal >= 50)
    newStrength = 3;
   else if (maxSignal >= 25)
    newStrength = 2;
   else if (maxSignal > 0)
    newStrength = 1;
  }
 }
 // If no active WiFi connection, newStrength stays 0

 if (newStrength != m_currentWifiStrength) {
  m_currentWifiStrength = newStrength;
  emit currentWifiStrengthChanged();
 }
}

void SystemManager::rebootSystem() {
 qDebug() << "Rebooting system...";
#ifdef Q_OS_UNIX
 // Try different approaches based on available tools and permissions
 if (QProcess::execute("which", QStringList() << "systemctl") == 0) {
  // systemd system
  QProcess::startDetached("systemctl", QStringList() << "reboot");
 } else if (getuid() == 0) {
  // Running as root, use direct reboot command
  QProcess::startDetached("reboot");
 } else {
  // Running as user, try with sudo
  QProcess::startDetached("sudo", QStringList() << "reboot");
 }
#elif defined(Q_OS_WIN)
 QProcess::startDetached("shutdown", QStringList() << "/r" << "/t" << "0");
#else
 qDebug() << "Reboot not implemented for this platform";
#endif
}

void SystemManager::shutdownSystem() {
 qDebug() << "Shutting down system...";
#ifdef Q_OS_WIN
 QProcess::startDetached("shutdown", QStringList() << "/s" << "/t" << "0");
#else
 // Try different approaches based on available tools and permissions
 if (QProcess::execute("which", QStringList() << "systemctl") == 0) {
  // systemd system
  QProcess::startDetached("systemctl", QStringList() << "poweroff");
 } else if (getuid() == 0) {
  // Running as root, use direct shutdown command
  QProcess::startDetached("shutdown", QStringList() << "-h" << "now");
 } else {
  // Running as user, try with sudo
  QProcess::startDetached("sudo", QStringList() << "shutdown" << "-h" << "now");
 }
#endif
}
