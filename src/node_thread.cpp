#include "include/node_thread.h"

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

 qDebug() << "NodeThread: Queued message" << messageId << "with action:" << action;
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
		// Initialize Node.js platform
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

 // Load main JavaScript file from filesystem
 QString jsPath = "../../src/js/index.js";		// Relative to build directory
 qDebug() << "NodeThread: Attempting to load main JS file from:" << jsPath;

 QFile jsFile(jsPath);
 QFileInfo jsFileInfo(jsPath);

 qDebug() << "NodeThread: File exists check:" << jsFile.exists();
 qDebug() << "NodeThread: Absolute path:" << jsFileInfo.absoluteFilePath();
 qDebug() << "NodeThread: File size:" << jsFileInfo.size() << "bytes";
 qDebug() << "NodeThread: File readable:" << jsFileInfo.isReadable();
 qDebug() << "NodeThread: Last modified:" << jsFileInfo.lastModified().toString();

 if (!jsFile.exists()) {
		qCritical() << "NodeThread: JavaScript file not found:" << jsPath;
		qCritical() << "NodeThread: Working directory:" << QDir::currentPath();
		return false;
 }

 if (!jsFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
		qCritical() << "NodeThread: Failed to open JavaScript file:" << jsPath;
		qCritical() << "NodeThread: Error:" << jsFile.errorString();
		return false;
 }

 qDebug() << "NodeThread: Reading JavaScript file content...";
 QTextStream in(&jsFile);
 QString jsCode = in.readAll();
 jsFile.close();

 qDebug() << "NodeThread: File read completed";
 qDebug() << "NodeThread: Content length:" << jsCode.length() << "characters";
 qDebug() << "NodeThread: Content preview (first 100 chars):" << jsCode.left(100);

 if (jsCode.isEmpty()) {
		qCritical() << "NodeThread: JavaScript file is empty:" << jsPath;
		return false;
 }

 qDebug() << "NodeThread: Successfully loaded" << jsCode.length() << "characters from" << jsPath;
 qDebug() << "NodeThread: Content hash:" << QString::number(qHash(jsCode), 16);

 // Validate JavaScript content before proceeding
 if (jsCode.trimmed().isEmpty()) {
		qCritical() << "NodeThread: JavaScript content is empty or contains only whitespace";
		return false;
 }

 // Basic validation to ensure it looks like JavaScript
 if (!jsCode.contains("handleMessage")) {
		qWarning() << "NodeThread: JavaScript code does not contain 'handleMessage' - this may cause runtime errors";
		qWarning() << "NodeThread: First 200 characters of loaded code:" << jsCode.left(200);
 }

 // Use src/js as working directory for Node.js modules
 QString workingDir = "src/js";
 qDebug() << "NodeThread: Using working directory:" << workingDir;

 auto loadenv_ret = node::LoadEnvironment(m_env, [&](const node::StartExecutionCallbackInfo& info) -> v8::MaybeLocal<v8::Value> {
		v8::Local<v8::Context> context = m_setup->context();
		v8::Isolate* isolate = context->GetIsolate();

		v8::Local<v8::Function> require = info.native_require;

		// Validate require function
		if (require.IsEmpty()) {
			qCritical() << "NodeThread: Native require function is empty";
			return v8::MaybeLocal<v8::Value>();
		}

		// Load bootstrap code from filesystem
		QString bootstrapPath = "../../src/js/bootstrap.js";		// Relative to build directory
		qDebug() << "NodeThread: Loading bootstrap file from:" << bootstrapPath;

		QFile bootstrapFile(bootstrapPath);
		QFileInfo bootstrapFileInfo(bootstrapPath);

		qDebug() << "NodeThread: Bootstrap file exists:" << bootstrapFile.exists();
		qDebug() << "NodeThread: Bootstrap absolute path:" << bootstrapFileInfo.absoluteFilePath();
		qDebug() << "NodeThread: Bootstrap file size:" << bootstrapFileInfo.size() << "bytes";

		if (!bootstrapFile.exists()) {
			qCritical() << "NodeThread: Bootstrap file not found:" << bootstrapPath;
			qCritical() << "NodeThread: Current working directory:" << QDir::currentPath();
			return v8::MaybeLocal<v8::Value>();
		}

		if (!bootstrapFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
			qCritical() << "NodeThread: Failed to open bootstrap file:" << bootstrapPath;
			qCritical() << "NodeThread: Bootstrap error:" << bootstrapFile.errorString();
			return v8::MaybeLocal<v8::Value>();
		}

		qDebug() << "NodeThread: Reading bootstrap file content...";
		QTextStream bootstrapStream(&bootstrapFile);
		QString bootstrapCode = bootstrapStream.readAll();
		bootstrapFile.close();

		qDebug() << "NodeThread: Bootstrap read completed";
		qDebug() << "NodeThread: Bootstrap content length:" << bootstrapCode.length() << "characters";
		qDebug() << "NodeThread: Bootstrap preview (first 50 chars):" << bootstrapCode.left(50);

		if (bootstrapCode.isEmpty()) {
			qCritical() << "NodeThread: Bootstrap file is empty:" << bootstrapPath;
			return v8::MaybeLocal<v8::Value>();
		}

		qDebug() << "NodeThread: Loaded bootstrap from filesystem:" << bootstrapPath;
		qDebug() << "NodeThread: Bootstrap content hash:" << QString::number(qHash(bootstrapCode), 16);

		v8::Local<v8::String> bootstrap = v8::String::NewFromUtf8(isolate, bootstrapCode.toStdString().c_str(), v8::NewStringType::kNormal).ToLocalChecked();

		v8::Local<v8::Script> bootstrapScript;
		v8::TryCatch try_catch(isolate);
		if (!v8::Script::Compile(context, bootstrap).ToLocal(&bootstrapScript)) {
			qCritical() << "NodeThread: Failed to compile bootstrap script";
			if (try_catch.HasCaught()) {
				v8::String::Utf8Value exception(isolate, try_catch.Exception());
				qCritical() << "NodeThread: Bootstrap compilation exception:" << *exception;
			}
			return v8::MaybeLocal<v8::Value>();
		}

		v8::Local<v8::Value> bootstrapFunctionResult;
		if (!bootstrapScript->Run(context).ToLocal(&bootstrapFunctionResult)) {
			qCritical() << "NodeThread: Failed to run bootstrap script";
			if (try_catch.HasCaught()) {
				v8::String::Utf8Value exception(isolate, try_catch.Exception());
				qCritical() << "NodeThread: Bootstrap execution exception:" << *exception;
			}
			return v8::MaybeLocal<v8::Value>();
		}

		if (!bootstrapFunctionResult->IsFunction()) {
			qCritical() << "NodeThread: Bootstrap script did not return a function";
			return v8::MaybeLocal<v8::Value>();
		}

		v8::Local<v8::Function> bootstrapFunction = bootstrapFunctionResult.As<v8::Function>();
		v8::Local<v8::Value> args[] = {require};
		v8::Local<v8::Value> result;
		if (!bootstrapFunction->Call(context, context->Global(), 1, args).ToLocal(&result)) {
			qCritical() << "NodeThread: Failed to call bootstrap function";
			if (try_catch.HasCaught()) {
				v8::String::Utf8Value exception(isolate, try_catch.Exception());
				qCritical() << "NodeThread: Bootstrap call exception:" << *exception;
			}
			return v8::MaybeLocal<v8::Value>();
		}

		qDebug() << "NodeThread: Bootstrap completed successfully";
		qDebug() << "NodeThread: Now compiling main JavaScript code...";
		qDebug() << "NodeThread: Converting" << jsCode.length() << "characters to V8 string";

		v8::Local<v8::String> source = v8::String::NewFromUtf8(isolate, jsCode.toStdString().c_str(), v8::NewStringType::kNormal).ToLocalChecked();

		qDebug() << "NodeThread: V8 string conversion completed";

		qDebug() << "NodeThread: Starting V8 script compilation...";
		v8::Local<v8::Script> script;
		if (!v8::Script::Compile(context, source).ToLocal(&script)) {
			qCritical() << "NodeThread: Failed to compile main JavaScript code";
			qCritical() << "NodeThread: Code length:" << jsCode.length() << "characters";
			qCritical() << "NodeThread: First 100 characters:" << jsCode.left(100);
			if (try_catch.HasCaught()) {
				v8::String::Utf8Value exception(isolate, try_catch.Exception());
				qCritical() << "NodeThread: Main script compilation exception:" << *exception;
				v8::Local<v8::Message> message = try_catch.Message();
				if (!message.IsEmpty()) {
					qCritical() << "NodeThread: Error line number:" << message->GetLineNumber(context).FromMaybe(-1);
					qCritical() << "NodeThread: Error start column:" << message->GetStartColumn(context).FromMaybe(-1);
				}
			}
			return v8::MaybeLocal<v8::Value>();
		}

		qDebug() << "NodeThread: Main JavaScript code compiled successfully";
		qDebug() << "NodeThread: Script compilation took" << QTime::currentTime().toString();

		qDebug() << "NodeThread: Starting main JavaScript execution...";
		v8::Local<v8::Value> scriptResult;
		if (!script->Run(context).ToLocal(&scriptResult)) {
			qCritical() << "NodeThread: Failed to execute main JavaScript code";
			if (try_catch.HasCaught()) {
				v8::String::Utf8Value exception(isolate, try_catch.Exception());
				qCritical() << "NodeThread: Main script execution exception:" << *exception;
				v8::Local<v8::Message> message = try_catch.Message();
				if (!message.IsEmpty()) {
					qCritical() << "NodeThread: Runtime error line:" << message->GetLineNumber(context).FromMaybe(-1);
					qCritical() << "NodeThread: Runtime error column:" << message->GetStartColumn(context).FromMaybe(-1);
				}
			}
			return v8::MaybeLocal<v8::Value>();
		}

		qDebug() << "NodeThread: Main JavaScript code executed successfully";
		qDebug() << "NodeThread: Script result type:" << (scriptResult->IsUndefined() ? "undefined" : scriptResult->IsFunction() ? "function" : scriptResult->IsObject() ? "object" : scriptResult->IsString() ? "string" : "other");
		return scriptResult;
 });

 if (loadenv_ret.IsEmpty()) {
		qCritical() << "NodeThread: LoadEnvironment failed - JavaScript execution error";
		qCritical() << "NodeThread: This usually indicates a syntax error or runtime exception in the JavaScript code";
		return false;
 }

 qDebug() << "NodeThread: LoadEnvironment completed successfully";
 qDebug() << "NodeThread: JavaScript loaded from filesystem";

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
		// qDebug() << "NodeThread: loop";

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

			// Now GetCurrentEventLoop should work because we have all required scopes
			uv_loop_t* loop = node::GetCurrentEventLoop(m_isolate);
			if (loop) {
				uv_run(loop, UV_RUN_NOWAIT);
			} else {
				qDebug() << "NodeThread: GetCurrentEventLoop still returns null";
			}
		}

		// Sleep briefly to prevent busy waiting
		QThread::msleep(100);
 }
}

void NodeThread::handleNodeMessage(const NodeMessage& message) {
 if (!m_env || !m_isolate) {
		message.callback(QJsonObject{{"status", "error"}, {"message", "Node.js not initialized"}});
		return;
 }

 qDebug() << "NodeThread: Processing message:" << message.action;

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

 qDebug() << "handleNodeMessage returning.";
}

void NodeThread::nativeCallback(const v8::FunctionCallbackInfo<v8::Value>& args) {
 if (!s_instance) {
		return;
 }

 v8::Isolate* isolate = args.GetIsolate();
 v8::HandleScope handle_scope(isolate);

 if (args.Length() > 1 && args[0]->IsString() && args[1]->IsObject()) {
		v8::Local<v8::Context> context = isolate->GetCurrentContext();

		// Get messageId from first argument
		v8::String::Utf8Value messageIdStr(isolate, args[0]);
		QString messageId = QString(*messageIdStr);

		// Find the callback for this message
		std::function<void(const QJsonObject&)> callback;
		{
			QMutexLocker locker(&s_instance->m_callbackMutex);
			if (s_instance->m_callbacks.contains(messageId)) {
				callback = s_instance->m_callbacks.take(messageId);		// Remove after taking
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
