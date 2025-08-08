#ifndef NODE_H
#define NODE_H

#include <QJSValue>
#include <QJsonDocument>
#include <QJsonObject>
#include <QObject>
#include <QMutex>
#include <QWaitCondition>
#include <functional>
#include <memory>

#include "node_thread.h"

enum class InitState {
    NotInitialized,
    Initializing,
    Initialized,
    Failed
};

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

#endif		// NODE_H