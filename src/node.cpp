#include "include/node.h"
#include <QDebug>

NodeJS::NodeJS(QObject *parent)
    : QObject(parent)
    , m_initialized(false)
{
}

NodeJS::~NodeJS() {
    shutdown();
}

bool NodeJS::initialize() {
    if (m_initialized) {
        qDebug() << "Node.js already initialized";
        return true;
    }

    qDebug() << "NodeJS: Initializing with NodeThread";
    
    m_nodeThread = std::make_unique<NodeThread>(this);
    
    if (!m_nodeThread->initialize()) {
        qWarning() << "NodeJS: Failed to initialize NodeThread";
        return false;
    }
    
    m_initialized = true;
    qDebug() << "NodeJS: Initialization completed successfully";
    return true;
}

void NodeJS::shutdown() {
    if (!m_initialized) {
        return;
    }
    
    qDebug() << "NodeJS: Shutting down";
    
    if (m_nodeThread) {
        m_nodeThread->shutdown();
        m_nodeThread.reset();
    }
    
    m_initialized = false;
    qDebug() << "NodeJS: Shutdown completed";
}

void NodeJS::msg(const QString &name, const QJsonObject &params, std::function<void(const QJsonObject&)> callback) {
    qDebug() << "NodeJS::msg() called with action:" << name;
    
    if (!m_initialized || !m_nodeThread) {
        qWarning() << "NodeJS: Not initialized";
        callback(QJsonObject{{"status", "error"}, {"message", "Node.js not initialized"}});
        return;
    }
    
    m_nodeThread->sendMessage(name, params, callback);
}

void NodeJS::msg(const QString &name, const QJsonObject &params, const QJSValue &callback) {
    if (callback.isCallable()) {
        msg(name, params, [callback](const QJsonObject& result) mutable {
            QJsonDocument doc(result);
            QString jsonString = doc.toJson(QJsonDocument::Compact);
            
            QJSValue callResult = callback.call({QJSValue(jsonString)});
            if (callResult.isError()) {
                qWarning() << "JavaScript callback error:" << callResult.toString();
            }
        });
    } else {
        msg(name, params);
    }
}

void NodeJS::msg(const QString &name, const QJsonObject &params) {
    msg(name, params, [this](const QJsonObject& result) {
        emit messageResponse(result);
    });
}