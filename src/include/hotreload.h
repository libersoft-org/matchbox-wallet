#pragma once

#include <QObject>
#include <QLocalServer>
#include <QLocalSocket>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QTimer>
#include <QFileSystemWatcher>
#include <QDir>

class HotReloadServer : public QObject {
    Q_OBJECT

public:
    explicit HotReloadServer(QQmlApplicationEngine* engine, QObject* parent = nullptr);
    ~HotReloadServer();

    void startServer(int port = 12345);
    void stopServer();

private slots:
    void handleNewConnection();
    void handleClientMessage();
    void handleFileChanged(const QString& path);

public slots:
    void saveNavigationState(const QString& componentName, const QString& pageId, const QVariantMap& properties);

private:
    void addDirectoryToWatcher(const QDir& dir);
    void reloadComponent(const QString& filePath);
    void reloadSpecificComponent(const QString& relativePath);
    bool findAndReloadComponent(const QString& componentName, const QString& componentUrl);
    bool findAndReloadInObject(QObject* obj, const QString& componentName);
    bool reloadObjectComponent(QObject* obj, const QString& componentName);
    void reloadEngine();
    void sendResponse(const QString& message);
    bool isMainFile(const QString& relativePath);
    bool isStaticComponent(const QString& relativePath);
    bool isPropertiesSafe(const QVariantMap& properties);
    
    QLocalServer* m_server;
    QLocalSocket* m_currentClient;
    QQmlApplicationEngine* m_engine;
    QFileSystemWatcher* m_fileWatcher;
    QString m_projectRoot;
    
    // Navigation state preservation across reloads
    QString m_lastComponentName;
    QString m_lastPageId;
    QVariantMap m_lastProperties;
};