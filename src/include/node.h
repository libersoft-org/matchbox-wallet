#ifndef NODE_H
#define NODE_H

#include <QJSValue>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMutex>
#include <QObject>
#include <QWaitCondition>
#include <functional>
#include <memory>

#ifdef ENABLE_NODEJS
#include "node_thread.h"
#endif

#ifdef ENABLE_NODEJS

enum class InitState { NotInitialized, Initializing, Initialized, Failed };

class NodeJS : public QObject {
 Q_OBJECT

public:
 explicit NodeJS(QObject *parent = nullptr);
 ~NodeJS();

 Q_INVOKABLE bool initialize();
 Q_INVOKABLE void shutdown();

 // Generic message function for QML with callback
 Q_INVOKABLE void msg(const QString &name, const QJsonObject &params, const QJSValue &callback);

 // Generic message function for QML without callback (uses signal)
 Q_INVOKABLE void msg(const QString &name, const QJsonObject &params = QJsonObject());

 // For C++ usage with callbacks (overload)
 void msg(const QString &name, const QJsonObject &params, std::function<void(const QJsonObject &)> callback);

signals:
 void messageResponse(const QJsonObject &result);
 void messageProcessed(const QJsonObject &result);
 void initializationFailed(const QString &error);

private:
 std::unique_ptr<NodeThread> m_nodeThread;
 InitState m_initState;
 QMutex m_initMutex;
 QWaitCondition m_initCondition;
};

#else // ENABLE_NODEJS

// Stub implementation when Node.js is disabled
class NodeJS : public QObject {
 Q_OBJECT

public:
 explicit NodeJS(QObject *parent = nullptr) : QObject(parent) {}
 ~NodeJS() {}

 Q_INVOKABLE bool initialize() { return true; }
 Q_INVOKABLE void shutdown() {}

 // Stub message functions that do nothing
 Q_INVOKABLE void msg(const QString &name, const QJsonObject &params, const QJSValue &callback) {}
 Q_INVOKABLE void msg(const QString &name, const QJsonObject &params = QJsonObject()) {}
 void msg(const QString &name, const QJsonObject &params, std::function<void(const QJsonObject &)> callback) {}

signals:
 void messageResponse(const QJsonObject &result);
 void messageProcessed(const QJsonObject &result);
 void initializationFailed(const QString &error);
};

#endif // ENABLE_NODEJS

#endif		// NODE_H
