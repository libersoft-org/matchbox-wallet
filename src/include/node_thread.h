#ifndef NODE_THREAD_H
#define NODE_THREAD_H

#include <libplatform/libplatform.h>
#include <node.h>
#include <uv.h>
#include <v8.h>

#include <QObject>
#include <QThread>
#include <QMutex>
#include <QWaitCondition>
#include <QQueue>
#include <QJsonObject>
#include <QUuid>
#include <QMap>
#include <memory>
#include <functional>
#include <atomic>

struct NodeMessage {
    QString messageId;
    QString action;
    QJsonObject params;
    std::function<void(const QJsonObject&)> callback;
};

class NodeThread : public QThread {
    Q_OBJECT

public:
    explicit NodeThread(QObject *parent = nullptr);
    ~NodeThread();
    
    bool initialize();
    void shutdown();
    
    // Direct message sending (thread-safe via Qt's signal-slot mechanism)
    void sendMessage(const QString &action, const QJsonObject &params, std::function<void(const QJsonObject&)> callback);

signals:
    void messageProcessed(const QJsonObject &result);

protected:
    void run() override;

private:
    bool initializeNodeEnvironment();
    bool loadJSEntryPoint();
    void processMessages();
    void handleNodeMessage(const NodeMessage &message);
    static void nativeCallback(const v8::FunctionCallbackInfo<v8::Value> &args);
    
    // Node.js environment
    std::unique_ptr<node::CommonEnvironmentSetup> m_setup;
    std::unique_ptr<node::MultiIsolatePlatform> m_platform;
    std::unique_ptr<node::InitializationResult> m_initResult;
    v8::Isolate *m_isolate;
    node::Environment *m_env;
    v8::Global<v8::Function> m_handleMessageFunction;
    
    // Thread synchronization
    QMutex m_messageMutex;
    QWaitCondition m_messageCondition;
    QQueue<NodeMessage> m_messageQueue;
    std::atomic<bool> m_running;
    
    // Callback storage for concurrent messages
    QMap<QString, std::function<void(const QJsonObject&)>> m_callbacks;
    QMutex m_callbackMutex;
    
    static const char* JS_ENTRY_PATH;
    static NodeThread* s_instance;
};

#endif // NODE_THREAD_H