#include "include/node_thread.h"

#ifdef ENABLE_NODEJS

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QTextStream>
#include <QTime>

NodeThread *NodeThread::s_instance = nullptr;

NodeThread::NodeThread(QObject *parent) : QThread(parent), m_isolate(nullptr), m_env(nullptr), m_running(false) {
	s_instance = this;
}

NodeThread::~NodeThread() {
	shutdown();
	s_instance = nullptr;
}

bool NodeThread::initialize() {
	// qDebug() << "NodeThread: Starting Node.js in dedicated thread";

	m_running = true;
	start(); // Start the QThread

	return true;
}

void NodeThread::shutdown() {
	if (m_running) {
		// qDebug() << "NodeThread: Shutting down Node.js thread";
		m_running = false;
		m_messageCondition.wakeAll();

		if (!wait(5000)) {
			qWarning() << "NodeThread: Thread didn't stop gracefully, terminating";
			terminate();
			wait(1000);
		}
	}
}

void NodeThread::sendMessage(const QString &action, const QJsonObject &params, std::function<void(const QJsonObject &)> callback) {
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
	message.callback = callback; // Keep for compatibility, but we'll use the map

	QMutexLocker locker(&m_messageMutex);
	m_messageQueue.enqueue(message);
	m_messageCondition.wakeAll();

	// qDebug() << "NodeThread: Queued message" << messageId << "with action:" << action;
}

void NodeThread::run() {
	// qDebug() << "NodeThread: Thread started, initializing Node.js environment";

	if (!initializeNodeEnvironment()) {
		qCritical() << "NodeThread: Failed to initialize Node.js environment";
		// Signal failure to main thread - this should exit the app
		emit initializationFailed("Failed to initialize Node.js environment. The application cannot continue.");
		return;
	}

	// qDebug() << "NodeThread: Node.js environment initialized, starting message loop";
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

	// qDebug() << "NodeThread: Thread cleanup completed";
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
			for (const std::string &err : errors) {
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

	} catch (const std::exception &e) {
		qWarning() << "NodeThread: Exception during initialization:" << e.what();
		return false;
	}
}

bool NodeThread::loadJSEntryPoint() {
	v8::Locker locker(m_isolate);
	v8::Isolate::Scope isolate_scope(m_isolate);
	v8::HandleScope handle_scope(m_isolate);
	v8::Context::Scope context_scope(m_setup->context());

	// Load bundle file directly
	QString bundlePath = "../../src/js/dist/bundle.cjs";
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

	// qDebug() << "NodeThread: Loading CommonJS bundle with Node.js integration";

	// Load environment and execute CommonJS bundle with proper context
	auto loadenv_ret = node::LoadEnvironment(m_env, [&](const node::StartExecutionCallbackInfo &info) -> v8::MaybeLocal<v8::Value> {
		v8::Local<v8::Context> context = m_setup->context();
		v8::Isolate *isolate = context->GetIsolate();
		v8::TryCatch try_catch(isolate);

		// Wrap the CommonJS module code in a function
		QString wrappedCode = QString("(function(exports, require, module, __filename, __dirname) {\n%1\n});").arg(bundleCode);

		v8::Local<v8::String> source = v8::String::NewFromUtf8(isolate, wrappedCode.toStdString().c_str()).ToLocalChecked();
		v8::Local<v8::String> filename = v8::String::NewFromUtf8(isolate, "bundle.cjs").ToLocalChecked();

		v8::ScriptOrigin origin(isolate, filename);
		v8::Local<v8::Script> script;
		if (!v8::Script::Compile(context, source, &origin).ToLocal(&script)) {
			if (try_catch.HasCaught()) {
				v8::String::Utf8Value exception(isolate, try_catch.Exception());
				qCritical() << "NodeThread: CommonJS compilation failed:" << *exception;
			}
			return v8::MaybeLocal<v8::Value>();
		}

		// Execute to get the module function
		v8::Local<v8::Value> moduleFunction;
		if (!script->Run(context).ToLocal(&moduleFunction)) {
			if (try_catch.HasCaught()) {
				v8::String::Utf8Value exception(isolate, try_catch.Exception());
				qCritical() << "NodeThread: CommonJS wrapper execution failed:" << *exception;
			}
			return v8::MaybeLocal<v8::Value>();
		}

		// Create CommonJS environment
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
		)")
													   .ToLocalChecked();

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
		// qDebug() << "NodeThread: Created require wrapper to handle node: prefixes";
		v8::Local<v8::String> filenameStr = v8::String::NewFromUtf8(isolate, bundlePath.toStdString().c_str()).ToLocalChecked();
		v8::Local<v8::String> dirnameStr = v8::String::NewFromUtf8(isolate, ".").ToLocalChecked();

		// Call the module function with CommonJS parameters
		v8::Local<v8::Function> moduleFunc = moduleFunction.As<v8::Function>();
		v8::Local<v8::Value> args[] = {exports, require, module, filenameStr, dirnameStr};

		v8::Local<v8::Value> result;
		if (!moduleFunc->Call(context, context->Global(), 5, args).ToLocal(&result)) {
			if (try_catch.HasCaught()) {
				v8::String::Utf8Value exception(isolate, try_catch.Exception());
				qCritical() << "NodeThread: CommonJS module execution failed:" << *exception;
			}
			return v8::MaybeLocal<v8::Value>();
		}

		// qDebug() << "NodeThread: CommonJS bundle executed successfully";
		return result;
	});

	if (loadenv_ret.IsEmpty()) {
		qCritical() << "NodeThread: LoadEnvironment failed";
		return false;
	}

	// Verify that globalThis.handleMessage was set by the bundle
	v8::Local<v8::Context> context = m_setup->context();
	v8::Local<v8::String> handleMessageName = v8::String::NewFromUtf8(m_isolate, "handleMessage").ToLocalChecked();

	v8::Local<v8::Value> handleMessageValue;
	if (!context->Global()->Get(context, handleMessageName).ToLocal(&handleMessageValue) || !handleMessageValue->IsFunction()) {
		qCritical() << "NodeThread: globalThis.handleMessage not found or not a function";
		qCritical() << "NodeThread: Make sure your bundle exports: globalThis.handleMessage = async (msg) => { ... }";

		// List available globals for debugging
		v8::Local<v8::Array> propertyNames;
		if (context->Global()->GetPropertyNames(context).ToLocal(&propertyNames)) {
			// qDebug() << "NodeThread: Available global properties:";
			for (uint32_t i = 0; i < propertyNames->Length(); i++) {
				v8::Local<v8::Value> propertyName;
				if (propertyNames->Get(context, i).ToLocal(&propertyName)) {
					v8::String::Utf8Value utf8(m_isolate, propertyName);
					// qDebug() << "  -" << *utf8;
				}
			}
		}
		return false;
	}

	// Cache the handleMessage function
	m_handleMessageFunction.Reset(m_isolate, handleMessageValue.As<v8::Function>());

	// Set up __nativeCallback for JS -> C++ communication
	v8::Local<v8::String> callbackName = v8::String::NewFromUtf8(m_isolate, "__nativeCallback").ToLocalChecked();
	v8::Local<v8::Function> callbackFunc = v8::Function::New(context, nativeCallback).ToLocalChecked();

	if (!context->Global()->Set(context, callbackName, callbackFunc).FromMaybe(false)) {
		qCritical() << "NodeThread: Failed to set __nativeCallback";
		return false;
	}

	// qDebug() << "NodeThread: JavaScript environment loaded successfully via native require()";
	return true;
}

void NodeThread::processMessages() {
	// qDebug() << "NodeThread: Starting non-blocking pump for Node/Qt integration";

	while (m_running) {
		bool didWork = false;

		// 0) Pull exactly one message if present (don’t hold the lock while executing JS)
		{
			QMutexLocker locker(&m_messageMutex);
			if (!m_messageQueue.isEmpty()) {
				NodeMessage message = m_messageQueue.dequeue();
				locker.unlock();
				handleNodeMessage(message);
				didWork = true;
			}
		}

		// 1..4) Pump Node/V8 once (non-blocking) and note if anything progressed
		didWork = pumpNodeOnce() || didWork;

		// If nothing happened, sleep or wait on the condition to avoid busy spin
		if (!didWork) {
			// Wait until we either get a message, or a short timeout to pulse the loop.
			QMutexLocker locker(&m_messageMutex);
			// Wakeups also come from shutdown() via wakeAll()
			m_messageCondition.wait(&m_messageMutex, 1 /* ms */);
		}
		// If you prefer no condition wait, at least:
		// else QThread::msleep(0); // yield
	}
}

bool NodeThread::pumpNodeOnce() {
	if (!m_env || !m_isolate) return false;

	bool progressed = false;

	v8::Locker lock(m_isolate);
	v8::Isolate::Scope isolate_scope(m_isolate);
	v8::HandleScope handle_scope(m_isolate);
	v8::Context::Scope context_scope(m_setup->context());

	// 1) Drain V8 platform (foreground) tasks (timers, immediate work)
	if (m_platform) {
		// DrainTasks behavior varies by Node.js version - some return bool, some void
		m_platform->DrainTasks(m_isolate);
		progressed = true; // Assume progress was made when we drain tasks
	} else {
		// Fallback to manual platform pumping if m_platform is not available
		// Note: In Node.js 18, platform pumping is typically handled by DrainTasks
		progressed = true; // Assume progress when fallback is used
	}

	// 2) Run libuv ready handles without blocking
	if (uv_loop_t *loop = node::GetCurrentEventLoop(m_isolate)) {
		int r = uv_run(loop, UV_RUN_NOWAIT); // >0 if work was done
		progressed = (r != 0) || progressed;
	}

	// 3) Run pending promise microtasks (continuations)
	m_isolate->PerformMicrotaskCheckpoint();

	// 4) If the loop appears idle, give Node a chance to flush beforeExit
	bool loop_idle = false;
	if (uv_loop_t *loop = node::GetCurrentEventLoop(m_isolate)) {
		loop_idle = !uv_loop_alive(loop);
	}

	if (loop_idle) {
		// Use the newer Maybe-based EmitProcessBeforeExit for Node.js 18+
		auto beforeExitResult = node::EmitProcessBeforeExit(m_env);
		(void)beforeExitResult; // Suppress unused variable warning

		// one more quick pass to flush anything scheduled by beforeExit
		if (uv_loop_t *loop2 = node::GetCurrentEventLoop(m_isolate)) {
			int r2 = uv_run(loop2, UV_RUN_NOWAIT);
			progressed = (r2 != 0) || progressed;
		}
		m_isolate->PerformMicrotaskCheckpoint();
	}

	return progressed;
}

void NodeThread::handleNodeMessage(const NodeMessage &message) {
	if (!m_env || !m_isolate) {
		message.callback(QJsonObject{{"status", "error"}, {"message", "Node.js not initialized"}});
		return;
	}

	// qDebug() << "NodeThread: Processing message:" << message.action << "with ID:" << message.messageId;

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

	// qDebug() << "handleNodeMessage returning.";
}

void NodeThread::nativeCallback(const v8::FunctionCallbackInfo<v8::Value> &args) {
	try {
		// qDebug() << "NodeThread::nativeCallback called with" << args.Length() << "arguments";

		if (!s_instance) {
			// qDebug() << "NodeThread::nativeCallback: No instance available";
			return;
		}

		v8::Isolate *isolate = args.GetIsolate();
		v8::HandleScope handle_scope(isolate);

		if (args.Length() > 1 && args[0]->IsString() && args[1]->IsObject()) {
			v8::Local<v8::Context> context = isolate->GetCurrentContext();

			// Get messageId from first argument
			v8::String::Utf8Value messageIdStr(isolate, args[0]);
			QString messageId = QString(*messageIdStr);
			// qDebug() << "NodeThread::nativeCallback: Processing callback for messageId:" << messageId;

			// Find the callback for this message
			std::function<void(const QJsonObject &)> callback;
			{
				QMutexLocker locker(&s_instance->m_callbackMutex);
				if (s_instance->m_callbacks.contains(messageId)) {
					callback = s_instance->m_callbacks.take(messageId);
					// qDebug() << "NodeThread::nativeCallback: Found and removed callback for messageId:" << messageId;
				} else {
					qWarning() << "NodeThread: No callback found for messageId:" << messageId;
					return;
				}
			}

			// Convert result object to JSON
			v8::Local<v8::Value> jsonObj;
			if (!context->Global()->Get(context, v8::String::NewFromUtf8(isolate, "JSON").ToLocalChecked()).ToLocal(&jsonObj)) {
				qWarning() << "NodeThread::nativeCallback: Failed to get JSON object";
				return;
			}

			v8::Local<v8::Object> json = jsonObj->ToObject(context).ToLocalChecked();
			v8::Local<v8::Value> stringifyFunc;
			if (!json->Get(context, v8::String::NewFromUtf8(isolate, "stringify").ToLocalChecked()).ToLocal(&stringifyFunc)) {
				qWarning() << "NodeThread::nativeCallback: Failed to get JSON.stringify function";
				return;
			}

			v8::Local<v8::Function> stringify = stringifyFunc.As<v8::Function>();
			v8::Local<v8::Value> argv[] = {args[1]}; // Use second argument (result object)
			v8::Local<v8::Value> result;
			if (!stringify->Call(context, json, 1, argv).ToLocal(&result)) {
				qWarning() << "NodeThread::nativeCallback: Failed to stringify result object";
				return;
			}

			v8::String::Utf8Value jsonStr(isolate, result);

			// Just parse and pass through - let QML handle the structure
			QJsonParseError error;
			QJsonDocument doc = QJsonDocument::fromJson(QByteArray(*jsonStr), &error);

			if (error.error == QJsonParseError::NoError) {
				// qDebug() << "NodeThread::nativeCallback: callback'ing for messageId:" << messageId;
				//  Only pass objects - wrap arrays and other types
				if (doc.isObject()) {
					callback(doc.object());
				} else {
					// Wrap non-object responses in a standardized object
					QJsonObject wrapper;
					wrapper["status"] = "success";
					if (doc.isArray()) {
						wrapper["data"] = doc.array();
					} else {
						// Handle primitive types
						wrapper["data"] = QJsonValue::fromVariant(doc.toVariant());
					}
					callback(wrapper);
				}
				// qDebug() << "NodeThread::nativeCallback: Callback executed successfully for messageId:" << messageId;
			} else {
				qWarning() << "NodeThread::nativeCallback: Failed to parse JSON for messageId:" << messageId << "Error:" << error.errorString();
				qWarning() << "NodeThread::nativeCallback: Raw JSON string:" << QString(*jsonStr);
			}
		} else {
			qWarning() << "NodeThread::nativeCallback: Invalid arguments - expected (string, object), got" << args.Length() << "arguments";
			if (args.Length() > 0) {
				qWarning() << "NodeThread::nativeCallback: First arg is string:" << args[0]->IsString();
			}
			if (args.Length() > 1) {
				qWarning() << "NodeThread::nativeCallback: Second arg is object:" << args[1]->IsObject();
			}
		}
	} catch (const std::exception &e) {
		qCritical() << "NodeThread::nativeCallback: Exception caught:" << e.what();
	} catch (...) {
		qCritical() << "NodeThread::nativeCallback: Unknown exception caught";
	}
}

#endif // ENABLE_NODEJS
