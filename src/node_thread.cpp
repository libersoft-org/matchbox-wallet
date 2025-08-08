#include "include/node_thread.h"
#include <QDebug>
#include <QDir>
#include <QCoreApplication>
#include <QJsonDocument>
#include <QFile>
#include <QTextStream>

const char* NodeThread::JS_ENTRY_PATH = "src/js/index.js";
const char* NodeThread::JS_ENTRY_QRC_PATH = ":/js/index.js";
NodeThread* NodeThread::s_instance = nullptr;

NodeThread::NodeThread(QObject *parent)
    : QThread(parent)
    , m_isolate(nullptr)
    , m_env(nullptr)
    , m_running(false)
{
    s_instance = this;
}

NodeThread::~NodeThread() {
    shutdown();
    s_instance = nullptr;
}

bool NodeThread::initialize() {
    qDebug() << "NodeThread: Starting Node.js in dedicated thread";
    
    m_running = true;
    start(); // Start the QThread
    
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

void NodeThread::sendMessage(const QString &action, const QJsonObject &params, std::function<void(const QJsonObject&)> callback) {
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
        m_initResult = node::InitializeOncePerProcess(args, {
            node::ProcessInitializationFlags::kNoInitializeV8,
            node::ProcessInitializationFlags::kNoInitializeNodeV8Platform
        });
        
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
        m_setup = node::CommonEnvironmentSetup::Create(
            m_platform.get(),
            &errors,
            m_initResult->args(),
            m_initResult->exec_args()
        );
        
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
    
    // Try to load JavaScript file from Qt resources first, then fall back to filesystem
    QString jsPath;
    QString jsCode;
    bool loadedFromQrc = false;

    // First try to load from Qt resources using the defined constant
    QString qrcPath = QString(JS_ENTRY_QRC_PATH);
    qDebug() << "NodeThread: Trying to load JavaScript from Qt resources:" << qrcPath;

    QFile qrcFile(qrcPath);
    if (qrcFile.exists()) {
        qDebug() << "NodeThread: Found JavaScript file in Qt resources:" << qrcPath;

        if (qrcFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QTextStream in(&qrcFile);
            jsCode = in.readAll();
            qrcFile.close();

            if (!jsCode.isEmpty()) {
                jsPath = qrcPath;
                loadedFromQrc = true;
                qDebug() << "NodeThread: Successfully loaded" << jsCode.length() << "characters from Qt resources";
            } else {
                qWarning() << "NodeThread: JavaScript file in Qt resources is empty:" << qrcPath;
            }
        } else {
            qWarning() << "NodeThread: Failed to open JavaScript file from Qt resources:" << qrcFile.errorString();
        }
    } else {
        qDebug() << "NodeThread: JavaScript file not found in Qt resources, trying filesystem";
    }

    // If not loaded from QRC, try filesystem as fallback
    if (!loadedFromQrc) {
        // Use the defined constant first
        jsPath = QString(JS_ENTRY_PATH);
        qDebug() << "NodeThread: Looking for JavaScript file at:" << jsPath;

        if (!QFile::exists(jsPath)) {
            qWarning() << "NodeThread: JavaScript file not found at constant path:" << jsPath;

            // Try relative to application directory
            QString appDir = QCoreApplication::applicationDirPath();
            QString relativePath = QDir(appDir).absoluteFilePath("../../src/js/index.js");
            qDebug() << "NodeThread: Trying relative path:" << relativePath;

            if (QFile::exists(relativePath)) {
                jsPath = relativePath;
                qDebug() << "NodeThread: Found JavaScript file at relative path:" << jsPath;
            } else {
                qCritical() << "NodeThread: JavaScript entry point not found at any expected location!";
                qCritical() << "NodeThread: Searched paths:";
                qCritical() << "  - " << qrcPath << " (Qt resources)";
                qCritical() << "  - " << QString(JS_ENTRY_PATH) << " (JS_ENTRY_PATH constant)";
                qCritical() << "  - " << relativePath << " (relative to app dir)";
                qCritical() << "NodeThread: Current working directory:" << QDir::currentPath();
                qCritical() << "NodeThread: Application directory:" << appDir;

                // List contents of directories to help with debugging
                QString jsDir = QDir(appDir).absoluteFilePath("../../src/js");
                QDir dir(jsDir);
                if (dir.exists()) {
                    qDebug() << "NodeThread: Contents of" << jsDir << ":";
                    QStringList entries = dir.entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
                    for (const QString& entry : entries) {
                        qDebug() << "  -" << entry;
                    }
                } else {
                    qCritical() << "NodeThread: JavaScript directory does not exist:" << jsDir;
                }

                // Also check current directory for debugging
                QDir currentDir(QDir::currentPath());
                qDebug() << "NodeThread: Contents of current directory" << currentDir.absolutePath() << ":";
                QStringList currentEntries = currentDir.entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
                for (const QString& entry : currentEntries) {
                    qDebug() << "  -" << entry;
                }

                return false;
            }
        } else {
            qDebug() << "NodeThread: Found JavaScript file at constant path:" << jsPath;
        }

        qDebug() << "NodeThread: Loading JS from filesystem:" << jsPath;

        QFile jsFile(jsPath);
        if (!jsFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            qCritical() << "NodeThread: Failed to open JavaScript file:" << jsPath;
            qCritical() << "NodeThread: File error:" << jsFile.errorString();
            qCritical() << "NodeThread: File permissions:" << QFileInfo(jsPath).permissions();
            qCritical() << "NodeThread: File size:" << QFileInfo(jsPath).size() << "bytes";
            return false;
        }

        QTextStream in(&jsFile);
        jsCode = in.readAll();
        jsFile.close();

        if (jsCode.isEmpty()) {
            qCritical() << "NodeThread: JavaScript file is empty:" << jsPath;
            qCritical() << "NodeThread: File size on disk:" << QFileInfo(jsPath).size() << "bytes";
            return false;
        }

        qDebug() << "NodeThread: Successfully read" << jsCode.length() << "characters from JavaScript file";
    }

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

    // Set up working directory for require function
    QString jsDir;
    if (loadedFromQrc) {
        // For QRC files, use a virtual directory path
        jsDir = ":/js";
        qDebug() << "NodeThread: Using Qt resources directory:" << jsDir;
    } else {
        // For filesystem files, use the actual directory
        QFileInfo fileInfo(jsPath);
        jsDir = fileInfo.absoluteDir().absolutePath();
        if (!QDir(jsDir).exists()) {
            qCritical() << "NodeThread: JavaScript working directory does not exist:" << jsDir;
            return false;
        }
        qDebug() << "NodeThread: Setting working directory to:" << jsDir;
    }

    auto loadenv_ret = node::LoadEnvironment(m_env, [&](const node::StartExecutionCallbackInfo& info) -> v8::MaybeLocal<v8::Value> {
        v8::Local<v8::Context> context = m_setup->context();
        v8::Isolate* isolate = context->GetIsolate();
        
        v8::Local<v8::Function> require = info.native_require;
        
        // Validate require function
        if (require.IsEmpty()) {
            qCritical() << "NodeThread: Native require function is empty";
            return v8::MaybeLocal<v8::Value>();
        }

        // Set up the standard require function for npm modules
        QString bootstrapCode;
        if (loadedFromQrc) {
            // For QRC-loaded files, create a more limited require that can load from resources
            bootstrapCode = QString(
                "(function(require) {\n"
                "  try {\n"
                "    const module = require('%1');\n"
                "    \n"
                "    // Create our custom require function that supports Qt resources\n"
                "    function customRequire(id) {\n"
                "      // For relative paths starting with ./ or ../, try to load from QRC\n"
                "      if (id.startsWith('./') || id.startsWith('../')) {\n"
                "        try {\n"
                "          // Convert relative path to QRC path\n"
                "          let resourcePath = id.replace(/^\\.\\//, '');\n"
                "          \n"
                "          // Try multiple file extensions following Node.js resolution order\n"
                "          const extensions = ['', '.js', '.json', '.node', '.mjs', '.cjs'];\n"
                "          \n"
                "          for (const ext of extensions) {\n"
                "            let tryPath;\n"
                "            if (resourcePath.includes('.') && ext === '') {\n"
                "              // If the path already has an extension, try it as-is first\n"
                "              tryPath = ':/js/' + resourcePath;\n"
                "            } else if (ext === '') {\n"
                "              // Try without extension (could be a directory with index.js)\n"
                "              tryPath = ':/js/' + resourcePath + '/index.js';\n"
                "            } else {\n"
                "              // Try with extension\n"
                "              tryPath = ':/js/' + resourcePath + ext;\n"
                "            }\n"
                "            \n"
                "            try {\n"
                "              return __loadFromQrc(tryPath);\n"
                "            } catch (e) {\n"
                "              // Continue to next extension\n"
                "              continue;\n"
                "            }\n"
                "          }\n"
                "          \n"
                "          // If we get here, none of the extensions worked\n"
                "          throw new Error('Module not found in QRC resources: ' + id);\n"
                "        } catch (e) {\n"
                "          console.error('Failed to load from QRC:', id, e.message);\n"
                "          // Fall through to normal require\n"
                "        }\n"
                "      }\n"
                "      \n"
                "      // For absolute module names, use normal Node.js require\n"
                "      // This won't work perfectly without a filesystem, but at least it won't crash\n"
                "      try {\n"
                "        return require(id);\n"
                "      } catch (e) {\n"
                "        throw new Error('Module not found: ' + id + ' (embedded mode has limited require support). Error: ' + e.message);\n"
                "      }\n"
                "    }\n"
                "    \n"
                "    // Copy properties from original require\n"
                "    Object.setPrototypeOf(customRequire, require);\n"
                "    Object.assign(customRequire, require);\n"
                "    \n"
                "    globalThis.require = customRequire;\n"
                "  } catch (e) {\n"
                "    console.error('Bootstrap error:', e.message);\n"
                "    throw e;\n"
                "  }\n"
                "})"
            ).arg("module");
        } else {
            // For filesystem files, use the normal setup
            bootstrapCode = QString(
                "(function(require) {\n"
                "  try {\n"
                "    const module = require('%1');\n"
                "    const publicRequire = module.createRequire('%2/');\n"
                "    \n"
                "    // Use normal filesystem require\n"
                "    globalThis.require = publicRequire;\n"
                "  } catch (e) {\n"
                "    console.error('Bootstrap error:', e.message);\n"
                "    throw e;\n"
                "  }\n"
                "})"
            ).arg("module", jsDir);
        }

        v8::Local<v8::String> bootstrap = v8::String::NewFromUtf8(
            isolate, bootstrapCode.toStdString().c_str(), v8::NewStringType::kNormal
        ).ToLocalChecked();
        
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
        v8::Local<v8::Value> args[] = { require };
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

        v8::Local<v8::String> source = v8::String::NewFromUtf8(
            isolate, jsCode.toStdString().c_str(), v8::NewStringType::kNormal
        ).ToLocalChecked();
        
        v8::Local<v8::Script> script;
        if (!v8::Script::Compile(context, source).ToLocal(&script)) {
            qCritical() << "NodeThread: Failed to compile main JavaScript code";
            qCritical() << "NodeThread: Code length:" << jsCode.length() << "characters";
            qCritical() << "NodeThread: First 100 characters:" << jsCode.left(100);
            if (try_catch.HasCaught()) {
                v8::String::Utf8Value exception(isolate, try_catch.Exception());
                qCritical() << "NodeThread: Main script compilation exception:" << *exception;
            }
            return v8::MaybeLocal<v8::Value>();
        }
        
        qDebug() << "NodeThread: Main JavaScript code compiled successfully";

        v8::Local<v8::Value> scriptResult;
        if (!script->Run(context).ToLocal(&scriptResult)) {
            qCritical() << "NodeThread: Failed to execute main JavaScript code";
            if (try_catch.HasCaught()) {
                v8::String::Utf8Value exception(isolate, try_catch.Exception());
                qCritical() << "NodeThread: Main script execution exception:" << *exception;
            }
            return v8::MaybeLocal<v8::Value>();
        }

        qDebug() << "NodeThread: Main JavaScript code executed successfully";
        return scriptResult;
    });
    
    if (loadenv_ret.IsEmpty()) {
        qCritical() << "NodeThread: LoadEnvironment failed - JavaScript execution error";
        qCritical() << "NodeThread: This usually indicates a syntax error or runtime exception in the JavaScript code";
        return false;
    }
    
    qDebug() << "NodeThread: LoadEnvironment completed successfully";
    qDebug() << "NodeThread: JavaScript loaded from:" << (loadedFromQrc ? "Qt resources" : "filesystem");

    // Get handleMessage function
    v8::Local<v8::Context> context = m_setup->context();
    v8::Local<v8::String> handleMessageName = v8::String::NewFromUtf8(
        m_isolate, "handleMessage", v8::NewStringType::kNormal
    ).ToLocalChecked();
    
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
        qCritical() << "NodeThread: handleMessage type:" << (handleMessageValue->IsString() ? "string" :
                                                           handleMessageValue->IsObject() ? "object" :
                                                           handleMessageValue->IsNumber() ? "number" : "unknown");
        qCritical() << "NodeThread: Make sure your JavaScript file exports a global handleMessage function";
        return false;
    }

    qDebug() << "NodeThread: handleMessage function found and verified";

    v8::Local<v8::Function> handleMessageFunc = handleMessageValue.As<v8::Function>();
    m_handleMessageFunction.Reset(m_isolate, handleMessageFunc);
    
    // Set up native callback
    v8::Local<v8::String> callbackName = v8::String::NewFromUtf8(
        m_isolate, "__nativeCallback", v8::NewStringType::kNormal
    ).ToLocalChecked();
    
    v8::Local<v8::Function> callbackFunc = v8::Function::New(
        context, nativeCallback
    ).ToLocalChecked();
    
    if (!context->Global()->Set(context, callbackName, callbackFunc).FromMaybe(false)) {
        qCritical() << "NodeThread: Failed to set native callback function";
        return false;
    }

    // Set up QRC loader function
    v8::Local<v8::String> qrcLoaderName = v8::String::NewFromUtf8(
        m_isolate, "__loadFromQrc", v8::NewStringType::kNormal
    ).ToLocalChecked();

    v8::Local<v8::Function> qrcLoaderFunc = v8::Function::New(
        context, loadFromQrc
    ).ToLocalChecked();

    if (!context->Global()->Set(context, qrcLoaderName, qrcLoaderFunc).FromMaybe(false)) {
        qCritical() << "NodeThread: Failed to set QRC loader function";
        return false;
    }

    qDebug() << "NodeThread: Native callback function set successfully";
    qDebug() << "NodeThread: QRC loader function set successfully";
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
                
                //qDebug() << "NodeThread: Processing message with action:" << message.action;
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

void NodeThread::handleNodeMessage(const NodeMessage &message) {
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
    
    v8::Local<v8::String> jsonStr = v8::String::NewFromUtf8(
        m_isolate,
        jsonData.constData(),
        v8::NewStringType::kNormal
    ).ToLocalChecked();
    
    // Parse JSON
    v8::Local<v8::Value> jsonObj;
    if (!context->Global()->Get(context, 
        v8::String::NewFromUtf8(m_isolate, "JSON").ToLocalChecked()).ToLocal(&jsonObj)) {
        message.callback(QJsonObject{{"status", "error"}, {"message", "Failed to get JSON object"}});
        return;
    }
    
    v8::Local<v8::Object> json = jsonObj->ToObject(context).ToLocalChecked();
    v8::Local<v8::Value> parseFunc;
    if (!json->Get(context, 
        v8::String::NewFromUtf8(m_isolate, "parse").ToLocalChecked()).ToLocal(&parseFunc)) {
        message.callback(QJsonObject{{"status", "error"}, {"message", "Failed to get JSON.parse"}});
        return;
    }
    
    v8::Local<v8::Function> parse = parseFunc.As<v8::Function>();
    v8::Local<v8::Value> parseArgs[] = { jsonStr };
    v8::Local<v8::Value> jsValue;
    if (!parse->Call(context, json, 1, parseArgs).ToLocal(&jsValue)) {
        message.callback(QJsonObject{{"status", "error"}, {"message", "Failed to parse JSON"}});
        return;
    }
    
    // Call handleMessage
    v8::Local<v8::Function> handleMessage = m_handleMessageFunction.Get(m_isolate);
    v8::Local<v8::Value> args[] = { jsValue };
    
    v8::Local<v8::Value> result;
    if (!handleMessage->Call(context, context->Global(), 1, args).ToLocal(&result)) {
        message.callback(QJsonObject{{"status", "error"}, {"message", "Failed to call handleMessage"}});
        return;
    }
    
    qDebug() << "handleNodeMessage returning.";
}

void NodeThread::nativeCallback(const v8::FunctionCallbackInfo<v8::Value> &args) {
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
                callback = s_instance->m_callbacks.take(messageId); // Remove after taking
            } else {
                qWarning() << "NodeThread: No callback found for messageId:" << messageId;
                return;
            }
        }
        
        // Convert result object to JSON
        v8::Local<v8::Value> jsonObj;
        if (!context->Global()->Get(context, 
            v8::String::NewFromUtf8(isolate, "JSON").ToLocalChecked()).ToLocal(&jsonObj)) {
            return;
        }
        
        v8::Local<v8::Object> json = jsonObj->ToObject(context).ToLocalChecked();
        v8::Local<v8::Value> stringifyFunc;
        if (!json->Get(context, 
            v8::String::NewFromUtf8(isolate, "stringify").ToLocalChecked()).ToLocal(&stringifyFunc)) {
            return;
        }
        
        v8::Local<v8::Function> stringify = stringifyFunc.As<v8::Function>();
        v8::Local<v8::Value> argv[] = { args[1] }; // Use second argument (result object)
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

void NodeThread::loadFromQrc(const v8::FunctionCallbackInfo<v8::Value> &args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::HandleScope handle_scope(isolate);
    v8::Local<v8::Context> context = isolate->GetCurrentContext();

    if (args.Length() != 1 || !args[0]->IsString()) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8(isolate, "loadFromQrc expects a string argument").ToLocalChecked()));
        return;
    }

    v8::String::Utf8Value qrcPath(isolate, args[0]);
    QString resourcePath = QString(*qrcPath);

    qDebug() << "NodeThread: Loading from QRC:" << resourcePath;

    // Load the file from Qt resources
    QFile qrcFile(resourcePath);
    if (!qrcFile.exists()) {
        QString errorMsg = QString("QRC resource not found: %1").arg(resourcePath);
        qCritical() << "NodeThread:" << errorMsg;
        isolate->ThrowException(v8::Exception::Error(
            v8::String::NewFromUtf8(isolate, errorMsg.toStdString().c_str()).ToLocalChecked()));
        return;
    }

    if (!qrcFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString errorMsg = QString("Failed to open QRC resource: %1 - %2").arg(resourcePath, qrcFile.errorString());
        qCritical() << "NodeThread:" << errorMsg;
        isolate->ThrowException(v8::Exception::Error(
            v8::String::NewFromUtf8(isolate, errorMsg.toStdString().c_str()).ToLocalChecked()));
        return;
    }

    QTextStream stream(&qrcFile);
    QString fileContent = stream.readAll();
    qrcFile.close();

    if (fileContent.isEmpty()) {
        qWarning() << "NodeThread: QRC resource is empty:" << resourcePath;
    }

    qDebug() << "NodeThread: Successfully loaded" << fileContent.length() << "characters from QRC:" << resourcePath;

    // Determine if this is a JSON file or JavaScript module
    QString fileName = resourcePath.split('/').last();

    if (fileName.endsWith(".json")) {
        // Parse as JSON and return the parsed object
        QJsonParseError parseError;
        QJsonDocument jsonDoc = QJsonDocument::fromJson(fileContent.toUtf8(), &parseError);

        if (parseError.error != QJsonParseError::NoError) {
            QString errorMsg = QString("JSON parse error in %1: %2").arg(resourcePath, parseError.errorString());
            qCritical() << "NodeThread:" << errorMsg;
            isolate->ThrowException(v8::Exception::SyntaxError(
                v8::String::NewFromUtf8(isolate, errorMsg.toStdString().c_str()).ToLocalChecked()));
            return;
        }

        // Convert QJsonDocument to V8 value
        QByteArray jsonData = jsonDoc.toJson(QJsonDocument::Compact);
        v8::Local<v8::String> jsonStr = v8::String::NewFromUtf8(
            isolate, jsonData.constData(), v8::NewStringType::kNormal
        ).ToLocalChecked();

        // Use JSON.parse to convert to JavaScript object
        v8::Local<v8::Value> jsonObj;
        if (!context->Global()->Get(context,
            v8::String::NewFromUtf8(isolate, "JSON").ToLocalChecked()).ToLocal(&jsonObj)) {
            isolate->ThrowException(v8::Exception::Error(
                v8::String::NewFromUtf8(isolate, "Failed to get JSON object").ToLocalChecked()));
            return;
        }

        v8::Local<v8::Object> json = jsonObj->ToObject(context).ToLocalChecked();
        v8::Local<v8::Value> parseFunc;
        if (!json->Get(context,
            v8::String::NewFromUtf8(isolate, "parse").ToLocalChecked()).ToLocal(&parseFunc)) {
            isolate->ThrowException(v8::Exception::Error(
                v8::String::NewFromUtf8(isolate, "Failed to get JSON.parse").ToLocalChecked()));
            return;
        }

        v8::Local<v8::Function> parse = parseFunc.As<v8::Function>();
        v8::Local<v8::Value> parseArgs[] = { jsonStr };
        v8::Local<v8::Value> result;
        if (!parse->Call(context, json, 1, parseArgs).ToLocal(&result)) {
            isolate->ThrowException(v8::Exception::Error(
                v8::String::NewFromUtf8(isolate, "Failed to parse JSON").ToLocalChecked()));
            return;
        }

        args.GetReturnValue().Set(result);
    } else {
        // Treat as JavaScript module - compile and execute it
        v8::Local<v8::String> source = v8::String::NewFromUtf8(
            isolate, fileContent.toStdString().c_str(), v8::NewStringType::kNormal
        ).ToLocalChecked();

        // Create a module-like environment with exports object
        QString moduleWrapper = QString(
            "(function(exports, module, require, __filename, __dirname) {\n"
            "%1\n"
            "return module.exports;\n"
            "})"
        ).arg(fileContent);

        v8::Local<v8::String> wrappedSource = v8::String::NewFromUtf8(
            isolate, moduleWrapper.toStdString().c_str(), v8::NewStringType::kNormal
        ).ToLocalChecked();

        v8::Local<v8::Script> script;
        if (!v8::Script::Compile(context, wrappedSource).ToLocal(&script)) {
            QString errorMsg = QString("Failed to compile JavaScript module: %1").arg(resourcePath);
            qCritical() << "NodeThread:" << errorMsg;
            isolate->ThrowException(v8::Exception::SyntaxError(
                v8::String::NewFromUtf8(isolate, errorMsg.toStdString().c_str()).ToLocalChecked()));
            return;
        }

        v8::Local<v8::Value> moduleFunction;
        if (!script->Run(context).ToLocal(&moduleFunction)) {
            QString errorMsg = QString("Failed to execute JavaScript module: %1").arg(resourcePath);
            qCritical() << "NodeThread:" << errorMsg;
            isolate->ThrowException(v8::Exception::Error(
                v8::String::NewFromUtf8(isolate, errorMsg.toStdString().c_str()).ToLocalChecked()));
            return;
        }

        // Create module context
        v8::Local<v8::Object> exports = v8::Object::New(isolate);
        v8::Local<v8::Object> module = v8::Object::New(isolate);
        module->Set(context, v8::String::NewFromUtf8(isolate, "exports").ToLocalChecked(), exports).ToChecked();

        // Get the global require function
        v8::Local<v8::Value> requireFunc;
        if (!context->Global()->Get(context,
            v8::String::NewFromUtf8(isolate, "require").ToLocalChecked()).ToLocal(&requireFunc)) {
            requireFunc = v8::Undefined(isolate);
        }

        QString filename = resourcePath;
        QString dirname = resourcePath.section('/', 0, -2); // Remove filename, keep directory

        // Call the wrapped module function
        v8::Local<v8::Function> moduleFunc = moduleFunction.As<v8::Function>();
        v8::Local<v8::Value> moduleArgs[] = {
            exports,
            module,
            requireFunc,
            v8::String::NewFromUtf8(isolate, filename.toStdString().c_str()).ToLocalChecked(),
            v8::String::NewFromUtf8(isolate, dirname.toStdString().c_str()).ToLocalChecked()
        };

        v8::Local<v8::Value> result;
        if (!moduleFunc->Call(context, context->Global(), 5, moduleArgs).ToLocal(&result)) {
            QString errorMsg = QString("Failed to execute module function: %1").arg(resourcePath);
            qCritical() << "NodeThread:" << errorMsg;
            isolate->ThrowException(v8::Exception::Error(
                v8::String::NewFromUtf8(isolate, errorMsg.toStdString().c_str()).ToLocalChecked()));
            return;
        }

        args.GetReturnValue().Set(result);
    }
}
