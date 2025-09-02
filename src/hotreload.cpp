#include "include/hotreload.h"
#include <QDebug>
#include <QDir>
#include <QQmlContext>
#include <QCoreApplication>
#include <QMetaObject>
#include <QTimer>
#include <QQmlComponent>
#include <QQuickItem>
#include <QFileInfo>

HotReloadServer::HotReloadServer(QQmlApplicationEngine* engine, QObject* parent)
    : QObject(parent)
    , m_server(new QLocalServer(this))
    , m_currentClient(nullptr)
    , m_engine(engine)
    , m_projectRoot(QDir::currentPath())
{
    // Watch all QML files recursively
    QDir qmlDir(m_projectRoot + "/src/qml");
    qInfo() << "Hot Reload: Initialized, watching QML files";
}

bool HotReloadServer::isPropertiesSafe(const QVariantMap& properties) {
    for (auto it = properties.begin(); it != properties.end(); ++it) {
        const QVariant& value = it.value();
        
        // Handle null/invalid variants (JavaScript null)
        if (!value.isValid() || value.isNull()) {
            continue; // Null values are safe to preserve
        }
        
        // Check for unsafe types
        if (value.userType() >= QMetaType::User) {
            return false; // Custom QML types, component instances
        }
        
        switch (value.typeId()) {
            case QMetaType::QString:
            case QMetaType::Int:
            case QMetaType::UInt:
            case QMetaType::LongLong:
            case QMetaType::ULongLong:
            case QMetaType::Double:
            case QMetaType::Float:
            case QMetaType::Bool:
            case QMetaType::QDateTime:
            case QMetaType::QDate:
            case QMetaType::QTime:
            case QMetaType::QUrl:
                continue; // Safe atomic types
                
            case QMetaType::QStringList:
                continue; // Safe
                
            case QMetaType::QVariantList: {
                // Check if all list items are safe
                QVariantList list = value.toList();
                for (const QVariant& item : list) {
                    if (item.userType() >= QMetaType::User) return false;
                    if (item.typeId() >= QMetaType::User) return false;
                }
                continue;
            }
            
            case QMetaType::QVariantMap: {
                // Recursively check nested map
                if (!isPropertiesSafe(value.toMap())) return false;
                continue;
            }
            
            default:
                qWarning() << "Hot Reload: Unsafe property type detected:" << QMetaType(value.typeId()).name() 
                          << "for key:" << it.key() << "value:" << value;
                return false; // Unknown or complex type
        }
    }
    return true;
}

void HotReloadServer::saveNavigationState(const QString& componentName, const QString& pageId, const QVariantMap& properties) {
    m_lastComponentName = componentName;
    m_lastPageId = pageId;
    
    // Only preserve properties if they're safe to serialize
    if (properties.isEmpty()) {
        m_lastProperties.clear();
        qInfo() << "Hot Reload: Saved navigation state -" << componentName << pageId << "(no properties)";
    } else {
        qInfo() << "Hot Reload: Evaluating properties safety for" << properties.keys().size() << "properties:" << properties.keys();
        if (isPropertiesSafe(properties)) {
            m_lastProperties = properties;
            qInfo() << "Hot Reload: Saved navigation state -" << componentName << pageId << "(with safe properties)";
        } else {
            m_lastProperties.clear();
            qWarning() << "Hot Reload: Saved navigation state -" << componentName << pageId << "(properties not preservable)";
        }
    }
}

HotReloadServer::~HotReloadServer() {
    stopServer();
}


bool HotReloadServer::findAndReloadInObject(QObject* obj, const QString& componentName) {
    if (!obj) return false;
    
    bool found = false;
    
    // Check if this object matches the component we're looking for
    QString objClassName = obj->metaObject()->className();
    
    // Check for QML component types - they often have "_QMLTYPE_" in the class name
    if (objClassName.contains(componentName) || objClassName.contains("_QMLTYPE_")) {
        // Additional check: see if the object has a source property that matches our component
        QVariant sourceProperty = obj->property("source");
        if (sourceProperty.isValid()) {
            QString source = sourceProperty.toString();
            if (source.contains(componentName + ".qml")) {
                found |= reloadObjectComponent(obj, componentName);
            }
        } else {
            // For direct QML components, check objectName or try to reload by type
            QString objectName = obj->objectName();
            if (objectName.isEmpty() || objectName.contains(componentName)) {
                found |= reloadObjectComponent(obj, componentName);
            }
        }
    }
    
    // Recursively search children
    const QObjectList children = obj->children();
    for (QObject* child : children) {
        found |= findAndReloadInObject(child, componentName);
    }
    
    return found;
}

bool HotReloadServer::reloadObjectComponent(QObject* obj, const QString& componentName) {
    // For QML Loader objects, we can set the source to force reload
    if (obj->metaObject()->className() == QString("QQuickLoader")) {
        QVariant currentSource = obj->property("source");
        if (currentSource.isValid()) {
            QString source = currentSource.toString();
            if (source.contains(componentName + ".qml")) {
                // Force reload by clearing and resetting source
                obj->setProperty("source", "");
                QTimer::singleShot(10, [obj, source]() {
                    obj->setProperty("source", source);
                });
                qInfo() << "Hot Reload: Reloaded Loader component" << source;
                return true;
            }
        }
    }
    
    // For other component types, try to trigger a refresh through property changes
    // This is a more generic approach that may work for various QML items
    QQuickItem* item = qobject_cast<QQuickItem*>(obj);
    if (item) {
        // Force a visual update
        item->update();
        qInfo() << "Hot Reload: Triggered update for" << obj->metaObject()->className();
        return true;
    }
    
    return false;
}

void HotReloadServer::startServer(int port) {
    QString serverName = QString("wallet_hotreload_%1").arg(port);
    QLocalServer::removeServer(serverName);
    
    if (m_server->listen(serverName)) {
        connect(m_server, &QLocalServer::newConnection,
                this, &HotReloadServer::handleNewConnection);
        qInfo() << "Hot Reload: Server listening on" << serverName;
    } else {
        qWarning() << "Hot Reload: Failed to start server:" << m_server->errorString();
    }
}

void HotReloadServer::stopServer() {
    if (m_server && m_server->isListening()) {
        m_server->close();
    }
}

void HotReloadServer::handleNewConnection() {
    m_currentClient = m_server->nextPendingConnection();
    connect(m_currentClient, &QLocalSocket::readyRead,
            this, &HotReloadServer::handleClientMessage);
    connect(m_currentClient, &QLocalSocket::disconnected,
            this, [this]() {
                if (m_currentClient) {
                    m_currentClient->deleteLater();
                    m_currentClient = nullptr;
                }
            });
    
    qInfo() << "Hot Reload: Client connected";
}

void HotReloadServer::handleClientMessage() {
    if (!m_currentClient) return;
    
    QByteArray data = m_currentClient->readAll();
    QString message = QString::fromUtf8(data).trimmed();
    
    if (message.startsWith("file:")) {
        QString filePath = message.mid(5);
        handleFileChanged(filePath);
    }
}

void HotReloadServer::handleFileChanged(const QString& path) {
	qInfo() << "Hot Reload: Detected change in" << path;
    // Add delay to ensure file write is complete, then reload
    QTimer::singleShot(330, [this, path]() {
        reloadComponent(path);
    });
}

void HotReloadServer::reloadComponent(const QString& filePath) {
    QString relativePath = QDir(m_projectRoot).relativeFilePath(filePath);
    qInfo() << "Hot Reload: Processing" << relativePath;
    
    // Smart reload logic based on file type
    if (isMainFile(relativePath)) {
        qInfo() << "Hot Reload: Main file changed - full reload required";
        reloadEngine();
    } else if (isStaticComponent(relativePath)) {
        qInfo() << "Hot Reload: Static component changed - full reload required";
        reloadEngine();
    } else {
        qInfo() << "Hot Reload: Component file changed - attempting smart reload";
        //reloadSpecificComponent(relativePath);
        reloadEngine();
    }
}

bool HotReloadServer::isMainFile(const QString& relativePath) {
    return relativePath.endsWith("Main.qml"); // uh huh can it be /Main.qml?
}

bool HotReloadServer::isStaticComponent(const QString& relativePath) {
    return relativePath.startsWith("src/qml/static/");
}

void HotReloadServer::reloadSpecificComponent(const QString& relativePath) {
    /*
     * SMART COMPONENT RELOADING - TODO:
     * 
     * The current implementation finds component instances correctly but only calls 
     * QQuickItem::update() which triggers a repaint, not a reload of QML source changes.
     * 
     * To implement true component reloading would require:
     * 
     * 1. COMPONENT INSTANCE REPLACEMENT:
     *    - Create new component instances from updated QML source
     *    - Replace old instances while preserving parent-child relationships
     *    - Transfer positioning, anchors, and layout properties
     * 
     * 2. STATE PRESERVATION:
     *    - Extract current property values from old instances
     *    - Restore dynamic properties and JavaScript-set values
     *    - Preserve property bindings and signal connections
     *    - Maintain animation states and focus handling
     * 
     * 3. DEPENDENCY CHAIN HANDLING:
     *    - Update components that import/use the changed component
     *    - Refresh parent components with size/behavior dependencies
     *    - Handle property binding chains that reference the component
     * 
     * 4. ENHANCED DETECTION:
     *    - Filter out Qt framework components (VirtualKeyboard, etc.)
     *    - More precise matching instead of substring matching
     *    - Only target components actually using the changed source file
     * 
     * COMPLEXITY: ~200-300 lines of complex C++, deep QML internals knowledge
     * RELIABILITY: Property bindings might break, animation states lost, memory management issues
     * 
     * CURRENT DECISION: Use full reload with navigation preservation - it's fast, reliable,
     * and seamless thanks to the navigation state preservation system.
     */
    
    qInfo() << "Hot Reload: Component-specific reload disabled, using full reload for reliability";
}

bool HotReloadServer::findAndReloadComponent(const QString& componentName, const QString& componentUrl) {
    // Clear the component cache to force reload
    m_engine->clearComponentCache();
    
    // Get root objects from the engine
    QList<QObject*> rootObjects = m_engine->rootObjects();
    if (rootObjects.isEmpty()) {
        qWarning() << "Hot Reload: No root objects found";
        return false;
    }
    
    // Search through all root objects and their children
    bool foundAndReloaded = false;
    for (QObject* root : rootObjects) {
        if (findAndReloadInObject(root, componentName)) {
            foundAndReloaded = true;
        }
    }
    
    if (foundAndReloaded) {
        qInfo() << "Hot Reload: Successfully reloaded component instances of" << componentName;
        return true;
    } else {
        qInfo() << "Hot Reload: No instances found for" << componentName;
        return false;
    }
}

void HotReloadServer::reloadEngine() {
    qInfo() << "Hot Reload: Full engine reload with navigation preservation";
    
    // Clear all cached components
    m_engine->clearComponentCache();
    
    // Clear all root objects first
    QList<QObject*> rootObjects = m_engine->rootObjects();
    for (QObject* obj : rootObjects) {
        obj->deleteLater();
    }
    
    // Wait a moment for deletion, then reload from filesystem
    QTimer::singleShot(50, [this]() {
        // Load from filesystem for hot reload - use the symlinked path in WalletModule
        QString mainQmlPath = QCoreApplication::applicationDirPath() + "/WalletModule/src/qml/Main.qml";
        QUrl mainQmlUrl = QUrl::fromLocalFile(mainQmlPath);
        
        // Refresh import paths to pick up new qmldir changes (new components)
        QStringList importPaths = m_engine->importPathList();
        m_engine->setImportPathList(QStringList());
        m_engine->setImportPathList(importPaths);
        qInfo() << "Hot Reload: Refreshed import paths for new components";
        
        qInfo() << "Hot Reload: Loading from filesystem:" << mainQmlUrl;
        m_engine->load(mainQmlUrl);
        
        // After reload, restore navigation
        QTimer::singleShot(100, [this]() {
            if (!m_engine->rootObjects().isEmpty()) {
                QObject* rootObject = m_engine->rootObjects().first();
                if (rootObject) {
                    qInfo() << "Hot Reload: Found root object, attempting to restore navigation";
                    
                    // Use saved C++ state for navigation restoration
                    if (!m_lastComponentName.isEmpty()) {
                        qInfo() << "Hot Reload: Restoring navigation to" << m_lastComponentName << m_lastPageId;
                        
                        // Call goPage with the saved parameters
                        bool result = QMetaObject::invokeMethod(rootObject, "goPage",
                            Q_ARG(QVariant, m_lastComponentName),
                            Q_ARG(QVariant, m_lastPageId),
                            Q_ARG(QVariant, QVariant::fromValue(m_lastProperties)));
                            
                        if (result) {
                            qInfo() << "Hot Reload: Successfully restored navigation";
                        } else {
                            qWarning() << "Hot Reload: Failed to call goPage() - method not found";
                        }
                    } else {
                        qInfo() << "Hot Reload: No navigation to restore";
                    }
                } else {
                    qWarning() << "Hot Reload: Root object is null";
                }
            } else {
                qWarning() << "Hot Reload: No root objects found after reload";
            }
        });
        
        sendResponse("reloaded");
    });
}

void HotReloadServer::sendResponse(const QString& message) {
    if (m_currentClient && m_currentClient->state() == QLocalSocket::ConnectedState) {
        m_currentClient->write(message.toUtf8());
        m_currentClient->flush();
    }
}