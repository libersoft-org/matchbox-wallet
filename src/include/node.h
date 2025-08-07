#ifndef NODE_H
#define NODE_H

#include <libplatform/libplatform.h>
#include <node.h>
#include <uv.h>
#include <v8.h>

#include <QJSValue>
#include <QJsonDocument>
#include <QJsonObject>
#include <QObject>
#include <functional>
#include <memory>

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

private:
 bool initializeNodePlatform();
 bool setupEnvironment();
 bool loadJSEntryPoint();
 void startEventLoop();
 void stopEventLoop();
 static void messageCallback(const v8::FunctionCallbackInfo<v8::Value> &args);

 std::unique_ptr<node::CommonEnvironmentSetup> m_setup;
 std::unique_ptr<node::MultiIsolatePlatform> m_platform;
 std::unique_ptr<node::InitializationResult> m_initResult;
 v8::Isolate *m_isolate;
 node::Environment *m_env;
 v8::Global<v8::Function> m_handleMessageFunction;
 bool m_initialized;

 static NodeJS *s_instance;
 std::function<void(const QJsonObject &)> m_currentCallback;

 static const char *JS_ENTRY_PATH;
};

#endif		// NODE_H