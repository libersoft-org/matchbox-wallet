#include "include/node_thread.h"

#ifdef ENABLE_NODEJS

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QTextStream>
#include <QTime>

NodeThread* NodeThread::s_instance = nullptr;

NodeThread::NodeThread(QObject* parent) : QThread(parent), m_isolate(nullptr), m_env(nullptr), m_running(false) {
 s_instance = this;
}

NodeThread::~NodeThread() {
 shutdown();
 s_instance = nullptr;
}

bool NodeThread::initialize() {
 qDebug() << "NodeThread: Starting Node.js in dedicated thread";

 m_running = true;
 start();		// Start the QThread

 return true;
}

void NodeThread::shutdown() {
 if (m_running) {
		qDebug() << "NodeThread: Shutting down Node.js thread";
		m_running = false;
		m_messageCondition.wakeAll();

		if (!wait(5000)) {
			qWarning() << "NodeThread: Thread didn't stop gracefully, terminating";
			terminate();
			wait(1000);
		}
 }
}

void NodeThread::sendMessage(const QString& action, const QJsonObject& params, std::function<void(const QJsonObject&)> callback) {
 // Generate unique message ID
 QString messageId = QUuid::createUuid().toString();

 // Store callback with message ID
 {
		QMutexLocker callbackLocker(&m_callbackMutex);
		m_callbacks[messageId] = callback;
 }

 NodeMessage message;
 message.messageId = messageId;
 message.action = action;
 message.params = params;
 message.callback = callback;		// Keep for compatibility, but we'll use the map

 QMutexLocker locker(&m_messageMutex);
 m_messageQueue.enqueue(message);
 m_messageCondition.wakeAll();

 //qDebug() << "NodeThread: Queued message" << messageId << "with action:" << action;
}

void NodeThread::run() {
 qDebug() << "NodeThread: Thread started, initializing Node.js environment";

 if (!initializeNodeEnvironment()) {
		qCritical() << "NodeThread: Failed to initialize Node.js environment";
		// Signal failure to main thread - this should exit the app
		emit initializationFailed("Failed to initialize Node.js environment. The application cannot continue.");
		return;
 }

 qDebug() << "NodeThread: Node.js environment initialized, starting message loop";
 processMessages();

 // Cleanup when thread exits
 if (m_env) {
		node::Stop(m_env);
 }

 m_handleMessageFunction.Reset();
 m_setup.reset();
 m_initResult.reset();

 if (m_platform) {
		v8::V8::Dispose();
		v8::V8::DisposePlatform();
		m_platform.reset();
 }

 static bool tornDown = false;
 if (!tornDown) {
		node::TearDownOncePerProcess();
		tornDown = true;
 }

 qDebug() << "NodeThread: Thread cleanup completed";
}

bool NodeThread::initializeNodeEnvironment() {
 try {
		// Initialize Node.js platform with V8 flags but keep platform control
		std::vector<std::string> args = {"wallet"};
		m_initResult = node::InitializeOncePerProcess(args, {node::ProcessInitializationFlags::kNoInitializeV8, node::ProcessInitializationFlags::kNoInitializeNodeV8Platform});

		if (!m_initResult) {
			qWarning() << "NodeThread: InitializeOncePerProcess failed";
			return false;
		}

		// Create V8 platform
		m_platform = node::MultiIsolatePlatform::Create(1);
		if (!m_platform) {
			qWarning() << "NodeThread: Failed to create V8 platform";
			return false;
		}

		v8::V8::InitializePlatform(m_platform.get());
		v8::V8::Initialize();

		// Create environment setup
		std::vector<std::string> errors;
		m_setup = node::CommonEnvironmentSetup::Create(m_platform.get(), &errors, m_initResult->args(), m_initResult->exec_args());

		if (!m_setup) {
			qWarning() << "NodeThread: Failed to create environment setup";
			for (const std::string& err : errors) {
				qWarning() << "Setup error:" << err.c_str();
			}
			return false;
		}

		m_isolate = m_setup->isolate();
		m_env = m_setup->env();

		// Load JavaScript entry point
		if (!loadJSEntryPoint()) {
			qWarning() << "NodeThread: Failed to load JavaScript entry point";
			return false;
		}

		return true;

 } catch (const std::exception& e) {
		qWarning() << "NodeThread: Exception during initialization:" << e.what();
		return false;
 }
}

bool NodeThread::loadJSEntryPoint() {
 v8::Locker locker(m_isolate);
 v8::Isolate::Scope isolate_scope(m_isolate);
 v8::HandleScope handle_scope(m_isolate);
 v8::Context::Scope context_scope(m_setup->context());

 qDebug() << "NodeThread: Using filesystem-only loading";

 // Load the bundled CommonJS file and execute it directly
 QString bundlePath = "../../src/js/dist/bundle.cjs";
 qDebug() << "NodeThread: Loading bundled CommonJS file:" << bundlePath;

 QFile bundleFile(bundlePath);
 if (!bundleFile.exists()) {
		qCritical() << "NodeThread: Bundle file not found:" << bundlePath;
		return false;
 }

 if (!bundleFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
		qCritical() << "NodeThread: Failed to open bundle file:" << bundlePath;
		return false;
 }

 QString bundleCode = QTextStream(&bundleFile).readAll();
 bundleFile.close();

 if (bundleCode.isEmpty()) {
		qCritical() << "NodeThread: Bundle file is empty:" << bundlePath;
		return false;
 }

 qDebug() << "NodeThread: Bundle loaded," << bundleCode.length() << "characters";

 auto loadenv_ret = node::LoadEnvironment(m_env, [&](const node::StartExecutionCallbackInfo& info) -> v8::MaybeLocal<v8::Value> {
		v8::Local<v8::Context> context = m_setup->context();
		v8::Isolate* isolate = context->GetIsolate();
		v8::TryCatch try_catch(isolate);

		qDebug() << "NodeThread: Executing bundled CommonJS code as script...";

		// Create CommonJS wrapper: (function(exports, require, module, __filename, __dirname) { ... })
		QString wrappedCode = QString("(function(exports, require, module, __filename, __dirname) {\n%1\n});").arg(bundleCode);
		
		// Compile the wrapped script
		v8::Local<v8::String> source = v8::String::NewFromUtf8(isolate, wrappedCode.toStdString().c_str(), v8::NewStringType::kNormal).ToLocalChecked();
		
		v8::Local<v8::Script> script;
		if (!v8::Script::Compile(context, source).ToLocal(&script)) {
			qCritical() << "NodeThread: Failed to compile bundled CommonJS code";
			if (try_catch.HasCaught()) {
				v8::String::Utf8Value exception(isolate, try_catch.Exception());
				qCritical() << "NodeThread: Compilation exception:" << *exception;
			}
			return v8::MaybeLocal<v8::Value>();
		}

		// Execute the wrapped script to get the module function
		v8::Local<v8::Value> moduleFunction;
		if (!script->Run(context).ToLocal(&moduleFunction)) {
			qCritical() << "NodeThread: Failed to execute wrapped CommonJS code";
			if (try_catch.HasCaught()) {
				v8::String::Utf8Value exception(isolate, try_catch.Exception());
				qCritical() << "NodeThread: Execution exception:" << *exception;
			}
			return v8::MaybeLocal<v8::Value>();
		}

		// Create CommonJS environment objects
		v8::Local<v8::Object> exports = v8::Object::New(isolate);
		v8::Local<v8::Object> module = v8::Object::New(isolate);
		module->Set(context, v8::String::NewFromUtf8(isolate, "exports").ToLocalChecked(), exports).Check();
		
		// Create a require wrapper that handles both node: prefixes and legacy names
		v8::Local<v8::String> requireWrapperCode = v8::String::NewFromUtf8(isolate, R"(
			(function(nativeRequire) {
				return function wrappedRequire(id) {
					// Convert node: prefixed modules to legacy names
					if (id.startsWith('node:')) {
						const legacyName = id.substring(5); // Remove 'node:' prefix
						return nativeRequire(legacyName);
					}
					return nativeRequire(id);
				};
			})
		)").ToLocalChecked();
		
		v8::Local<v8::Script> wrapperScript;
		if (!v8::Script::Compile(context, requireWrapperCode).ToLocal(&wrapperScript)) {
			qCritical() << "NodeThread: Failed to compile require wrapper";
			return v8::MaybeLocal<v8::Value>();
		}
		
		v8::Local<v8::Value> wrapperFactory;
		if (!wrapperScript->Run(context).ToLocal(&wrapperFactory)) {
			qCritical() << "NodeThread: Failed to execute require wrapper factory";
			return v8::MaybeLocal<v8::Value>();
		}
		
		// Create wrapped require
		v8::Local<v8::Function> wrapperFactoryFunc = wrapperFactory.As<v8::Function>();
		v8::Local<v8::Value> factoryArgs[] = {info.native_require};
		v8::Local<v8::Value> wrappedRequireValue;
		if (!wrapperFactoryFunc->Call(context, context->Global(), 1, factoryArgs).ToLocal(&wrappedRequireValue)) {
			qCritical() << "NodeThread: Failed to create wrapped require function";
			return v8::MaybeLocal<v8::Value>();
		}
		
		v8::Local<v8::Function> require = wrappedRequireValue.As<v8::Function>();
		qDebug() << "NodeThread: Created require wrapper to handle node: prefixes";
		v8::Local<v8::String> filename = v8::String::NewFromUtf8(isolate, "bundle.cjs").ToLocalChecked();
		v8::Local<v8::String> dirname = v8::String::NewFromUtf8(isolate, ".").ToLocalChecked();

		// Call the module function with CommonJS parameters
		v8::Local<v8::Function> moduleFunc = moduleFunction.As<v8::Function>();
		v8::Local<v8::Value> args[] = {exports, require, module, filename, dirname};
		
		v8::Local<v8::Value> result;
		if (!moduleFunc->Call(context, context->Global(), 5, args).ToLocal(&result)) {
			qCritical() << "NodeThread: Failed to call module function";
			if (try_catch.HasCaught()) {
				v8::String::Utf8Value exception(isolate, try_catch.Exception());
				qCritical() << "NodeThread: Module execution exception:" << *exception;
			}
			return v8::MaybeLocal<v8::Value>();
		}

		qDebug() << "NodeThread: CommonJS module executed successfully";
		return result;
 });

 if (loadenv_ret.IsEmpty()) {
		qCritical() << "NodeThread: LoadEnvironment failed - JavaScript execution error";
		qCritical() << "NodeThread: This usually indicates a syntax error or runtime exception in the JavaScript code";
		return false;
 }

 qDebug() << "NodeThread: LoadEnvironment completed successfully";
 qDebug() << "NodeThread: CommonJS bundle executed successfully";

 // Get handleMessage function
 v8::Local<v8::Context> context = m_setup->context();
 v8::Local<v8::String> handleMessageName = v8::String::NewFromUtf8(m_isolate, "handleMessage", v8::NewStringType::kNormal).ToLocalChecked();

 v8::Local<v8::Value> handleMessageValue;
 if (!context->Global()->Get(context, handleMessageName).ToLocal(&handleMessageValue)) {
		qCritical() << "NodeThread: Failed to get handleMessage from global context";
		return false;
 }

 if (handleMessageValue->IsUndefined()) {
		qCritical() << "NodeThread: handleMessage is undefined in JavaScript context";
		qCritical() << "NodeThread: Make sure your JavaScript file defines global.handleMessage";

		// List available global properties for debugging
		v8::Local<v8::Array> propertyNames;
		if (context->Global()->GetPropertyNames(context).ToLocal(&propertyNames)) {
			qDebug() << "NodeThread: Available global properties:";
			for (uint32_t i = 0; i < propertyNames->Length(); i++) {
				v8::Local<v8::Value> propertyName;
				if (propertyNames->Get(context, i).ToLocal(&propertyName)) {
					v8::String::Utf8Value utf8(m_isolate, propertyName);
					qDebug() << "  -" << *utf8;
				}
			}
		}
		return false;
 }

 if (!handleMessageValue->IsFunction()) {
		qCritical() << "NodeThread: handleMessage is not a function in JavaScript context";
		qCritical() << "NodeThread: handleMessage type:" << (handleMessageValue->IsString() ? "string" : handleMessageValue->IsObject() ? "object" : handleMessageValue->IsNumber() ? "number" : "unknown");
		qCritical() << "NodeThread: Make sure your JavaScript file exports a global handleMessage function";
		return false;
 }

 qDebug() << "NodeThread: handleMessage function found and verified";

 v8::Local<v8::Function> handleMessageFunc = handleMessageValue.As<v8::Function>();
 m_handleMessageFunction.Reset(m_isolate, handleMessageFunc);

 // Set up native callback
 v8::Local<v8::String> callbackName = v8::String::NewFromUtf8(m_isolate, "__nativeCallback", v8::NewStringType::kNormal).ToLocalChecked();

 v8::Local<v8::Function> callbackFunc = v8::Function::New(context, nativeCallback).ToLocalChecked();

 if (!context->Global()->Set(context, callbackName, callbackFunc).FromMaybe(false)) {
		qCritical() << "NodeThread: Failed to set native callback function";
		return false;
 }

 qDebug() << "NodeThread: Native callback function set successfully";
 qDebug() << "NodeThread: JavaScript environment loaded successfully";
 return true;
}

void NodeThread::processMessages() {
 qDebug() << "NodeThread: Starting infinite loop for message processing and event loop";

 while (m_running) {
		//qDebug() << "NodeThread: loop";

		{
			QMutexLocker locker(&m_messageMutex);
			if (!m_messageQueue.isEmpty()) {
				NodeMessage message = m_messageQueue.dequeue();
				locker.unlock();

				// qDebug() << "NodeThread: Processing message with action:" << message.action;
				handleNodeMessage(message);
			}
		}

		// Run Node.js event loop to process async operations
		if (m_env && m_isolate) {
			v8::Locker v8locker(m_isolate);
			v8::Isolate::Scope isolate_scope(m_isolate);
			v8::HandleScope handle_scope(m_isolate);

			// Add the missing Context::Scope to make GetCurrentEventLoop work
			v8::Context::Scope context_scope(m_setup->context());

			// Process any pending microtasks (promise continuations)
			m_isolate->PerformMicrotaskCheckpoint();

			// Now GetCurrentEventLoop should work because we have all required scopes
			uv_loop_t* loop = node::GetCurrentEventLoop(m_isolate);
			if (loop) {
                while (uv_run(loop, UV_RUN_NOWAIT) != 0) {
                      m_isolate->PerformMicrotaskCheckpoint();
                }
			} else {
				qDebug() << "NodeThread: GetCurrentEventLoop still returns null";
			}
		}

		// Sleep briefly to prevent busy waiting
		QThread::msleep(10);
 }
}

void NodeThread::handleNodeMessage(const NodeMessage& message) {
 if (!m_env || !m_isolate) {
		message.callback(QJsonObject{{"status", "error"}, {"message", "Node.js not initialized"}});
		return;
 }

 //qDebug() << "NodeThread: Processing message:" << message.action;

 v8::Locker locker(m_isolate);
 v8::Isolate::Scope isolate_scope(m_isolate);
 v8::HandleScope handle_scope(m_isolate);
 v8::Context::Scope context_scope(m_setup->context());

 v8::Local<v8::Context> context = m_setup->context();

 // Create message object with messageId
 QJsonObject jsObject;
 jsObject["messageId"] = message.messageId;
 jsObject["action"] = message.action;
 jsObject["data"] = message.params;

 QJsonDocument doc(jsObject);
 QByteArray jsonData = doc.toJson(QJsonDocument::Compact);

 v8::Local<v8::String> jsonStr = v8::String::NewFromUtf8(m_isolate, jsonData.constData(), v8::NewStringType::kNormal).ToLocalChecked();

 // Parse JSON
 v8::Local<v8::Value> jsonObj;
 if (!context->Global()->Get(context, v8::String::NewFromUtf8(m_isolate, "JSON").ToLocalChecked()).ToLocal(&jsonObj)) {
		message.callback(QJsonObject{{"status", "error"}, {"message", "Failed to get JSON object"}});
		return;
 }

 v8::Local<v8::Object> json = jsonObj->ToObject(context).ToLocalChecked();
 v8::Local<v8::Value> parseFunc;
 if (!json->Get(context, v8::String::NewFromUtf8(m_isolate, "parse").ToLocalChecked()).ToLocal(&parseFunc)) {
		message.callback(QJsonObject{{"status", "error"}, {"message", "Failed to get JSON.parse"}});
		return;
 }

 v8::Local<v8::Function> parse = parseFunc.As<v8::Function>();
 v8::Local<v8::Value> parseArgs[] = {jsonStr};
 v8::Local<v8::Value> jsValue;
 if (!parse->Call(context, json, 1, parseArgs).ToLocal(&jsValue)) {
		message.callback(QJsonObject{{"status", "error"}, {"message", "Failed to parse JSON"}});
		return;
 }

 // Call handleMessage
 v8::Local<v8::Function> handleMessage = m_handleMessageFunction.Get(m_isolate);
 v8::Local<v8::Value> args[] = {jsValue};

 v8::Local<v8::Value> result;
 if (!handleMessage->Call(context, context->Global(), 1, args).ToLocal(&result)) {
		message.callback(QJsonObject{{"status", "error"}, {"message", "Failed to call handleMessage"}});
		return;
 }

 // Since handleMessage is async and returns a Promise, we need to ensure
 // the microtask queue is processed to allow the promise chain to continue
 m_isolate->PerformMicrotaskCheckpoint();

 //qDebug() << "handleNodeMessage returning.";
}

void NodeThread::nativeCallback(const v8::FunctionCallbackInfo<v8::Value>& args) {
 //qDebug() << "NodeThread::nativeCallback called with" << args.Length() << "arguments";
 
 if (!s_instance) {
		qDebug() << "NodeThread::nativeCallback: No instance available";
		return;
 }

 v8::Isolate* isolate = args.GetIsolate();
 v8::HandleScope handle_scope(isolate);

 if (args.Length() > 1 && args[0]->IsString() && args[1]->IsObject()) {
		v8::Local<v8::Context> context = isolate->GetCurrentContext();

		// Get messageId from first argument
		v8::String::Utf8Value messageIdStr(isolate, args[0]);
		QString messageId = QString(*messageIdStr);
		//qDebug() << "NodeThread::nativeCallback: Processing callback for messageId:" << messageId;

		// Find the callback for this message
		std::function<void(const QJsonObject&)> callback;
		{
			QMutexLocker locker(&s_instance->m_callbackMutex);
			if (s_instance->m_callbacks.contains(messageId)) {
				callback = s_instance->m_callbacks.take(messageId);		// Remove after taking
				qDebug() << "NodeThread::nativeCallback: Found and removed callback for messageId:" << messageId;
			} else {
				qWarning() << "NodeThread: No callback found for messageId:" << messageId;
				return;
			}
		}

		// Convert result object to JSON
		v8::Local<v8::Value> jsonObj;
		if (!context->Global()->Get(context, v8::String::NewFromUtf8(isolate, "JSON").ToLocalChecked()).ToLocal(&jsonObj)) {
			return;
		}

		v8::Local<v8::Object> json = jsonObj->ToObject(context).ToLocalChecked();
		v8::Local<v8::Value> stringifyFunc;
		if (!json->Get(context, v8::String::NewFromUtf8(isolate, "stringify").ToLocalChecked()).ToLocal(&stringifyFunc)) {
			return;
		}

		v8::Local<v8::Function> stringify = stringifyFunc.As<v8::Function>();
		v8::Local<v8::Value> argv[] = {args[1]};		// Use second argument (result object)
		v8::Local<v8::Value> result;
		if (!stringify->Call(context, json, 1, argv).ToLocal(&result)) {
			return;
		}

		v8::String::Utf8Value jsonStr(isolate, result);

		QJsonParseError error;
		QJsonDocument doc = QJsonDocument::fromJson(QByteArray(*jsonStr), &error);

		if (error.error == QJsonParseError::NoError && doc.isObject()) {
			callback(doc.object());
		}
 }
}

#endif // ENABLE_NODEJS
