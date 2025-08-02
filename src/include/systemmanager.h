#ifndef SYSTEMMANAGER_H
#define SYSTEMMANAGER_H

#include <QObject>
#include <qqmlintegration.h>

class SystemManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit SystemManager(QObject *parent = nullptr);

public slots:
    void rebootSystem();
    void shutdownSystem();
};

#endif // SYSTEMMANAGER_H
