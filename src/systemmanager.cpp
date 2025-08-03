#include "include/systemmanager.h"

#include <QDebug>
#include <QProcess>

SystemManager::SystemManager(QObject *parent) : QObject(parent) {}

void SystemManager::rebootSystem() {
 qDebug() << "Rebooting system...";
#ifdef Q_OS_UNIX
 QProcess::startDetached("reboot");
#elif defined(Q_OS_WIN)
 QProcess::startDetached("shutdown", QStringList() << "/r" << "/t" << "0");
#else
 qDebug() << "Reboot not implemented for this platform";
#endif
}

void SystemManager::shutdownSystem() {
 qDebug() << "Shutting down system...";
#ifdef Q_OS_UNIX
 QProcess::startDetached("shutdown", QStringList() << "-h" << "now");
#elif defined(Q_OS_WIN)
 QProcess::startDetached("shutdown", QStringList() << "/s" << "/t" << "0");
#else
 qDebug() << "Shutdown not implemented for this platform";
#endif
}
