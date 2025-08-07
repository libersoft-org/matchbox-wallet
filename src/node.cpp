#include "include/node.h"
#include <QDebug>
#include <QDir>
#include <QCoreApplication>
#include <QJsonDocument>
#include <QFile>
#include <QTextStream>
#include <QJSValue>
#include <QQmlEngine>
#include <QJSEngine>

const char* NodeJS::JS_ENTRY_PATH = "src/js/index.js";
NodeJS* NodeJS::s_instance = nullptr;

NodeJS::NodeJS(QObject *parent)
    : QObject(parent)
    , m_isolate(nullptr)
    , m_env(nullptr)
    , m_initialized(false)
    , m_eventLoopTimer(nullptr)
{
    s_instance = this;
}

NodeJS::~NodeJS() {
    shutdown();
    s_instance = nullptr;
}

bool NodeJS::initialize() {
    if (m_initialized) {
        qDebug() << "Node.js already initialized";
        return true;
    }

    qDebug() << "Starting Node.js initialization...";
    
    try {
        qDebug() << "Step 1: Initializing Node.js platform...";
        if (!initializeNodePlatform()) {
            qWarning() << "Failed to initialize Node.js platform";
            return false;
        }
        qDebug() << "Step 1: Node.js platform initialized successfully";
        
        qDebug() << "Step 2: Setting up Node.js environment...";
        if (!setupEnvironment()) {
            qWarning() << "Failed to setup Node.js environment";
            return false;
        }
        qDebug() << "Step 2: Node.js environment setup successfully";
        
        qDebug() << "Step 3: Loading JavaScript entry point...";
        if (!loadJSEntryPoint()) {
            qWarning() << "Failed to load JavaScript entry point";
            return false;
        }
        qDebug() << "Step 3: JavaScript entry point loaded successfully";
        
        qDebug() << "Step 4: Starting background event loop...";
        // Start the background event loop
        startEventLoop();
        qDebug() << "Step 4: Background event loop started";
        
        m_initialized = true;
        qDebug() << "Node.js embedded instance initialized successfully";
        return true;
        
    } catch (const std::exception& e) {
        qWarning() << "Failed to initialize Node.js:" << e.what();
        return false;
    } catch (...) {
        qWarning() << "Unknown error during Node.js initialization";
        return false;
    }
}

bool NodeJS::initializeNodePlatform() {
    // Initialize Node.js once per process - following exact documentation pattern
    static bool nodeInitialized = false;
    if (!nodeInitialized) {
        qDebug() << "Setting up Node.js arguments...";
        std::vector<std::string> args = {"wallet"};
        
        qDebug() << "Calling node::InitializeOncePerProcess...";
        m_initResult = node::InitializeOncePerProcess(args, {
            node::ProcessInitializationFlags::kNoInitializeV8,
            node::ProcessInitializationFlags::kNoInitializeNodeV8Platform
        });
        
        if (!m_initResult) {
            qWarning() << "Node.js InitializeOncePerProcess failed - returned nullptr";
            return false;
        }
        qDebug() << "Node.js InitializeOncePerProcess completed successfully";
        nodeInitialized = true;
    }
    
    qDebug() << "Creating V8 MultiIsolatePlatform...";
    // Create V8 platform - using node::MultiIsolatePlatform
    m_platform = node::MultiIsolatePlatform::Create(4);
    if (!m_platform) {
        qWarning() << "Failed to create V8 platform";
        return false;
    }
    qDebug() << "V8 MultiIsolatePlatform created successfully";
    
    qDebug() << "Initializing V8 platform...";
    v8::V8::InitializePlatform(m_platform.get());
    v8::V8::Initialize();
    qDebug() << "V8 platform initialized successfully";
    
    return true;
}

bool NodeJS::setupEnvironment() {
    if (!m_initResult) {
        qWarning() << "No initialization result available";
        return false;
    }
    
    std::vector<std::string> errors;
    
    qDebug() << "Creating CommonEnvironmentSetup with result args...";
    // Create environment setup using the result from InitializeOncePerProcess
    m_setup = node::CommonEnvironmentSetup::Create(
        m_platform.get(),
        &errors,
        m_initResult->args(),
        m_initResult->exec_args()
    );
    
    if (!m_setup) {
        qWarning() << "Failed to create Node.js environment setup";
        for (const std::string& err : errors) {
            qWarning() << "Setup error:" << err.c_str();
        }
        return false;
    }
    
    m_isolate = m_setup->isolate();
    m_env = m_setup->env();
    
    return true;
}

bool NodeJS::loadJSEntryPoint() {
    if (!m_isolate || !m_env) {
        qWarning() << "Node.js environment not ready";
        return false;
    }
    
    v8::Locker locker(m_isolate);
    v8::Isolate::Scope isolate_scope(m_isolate);
    v8::HandleScope handle_scope(m_isolate);
    v8::Context::Scope context_scope(m_setup->context());
    
    // Construct path to JS entry point
    QString appDir = QCoreApplication::applicationDirPath();
    QString jsPath = QDir(appDir).absoluteFilePath(QString(JS_ENTRY_PATH));
    
    if (!QFile::exists(jsPath)) {
        jsPath = QString(JS_ENTRY_PATH);
        if (!QFile::exists(jsPath)) {
            qWarning() << "JavaScript entry point not found:" << jsPath;
            return false;
        }
    }
    
    qDebug() << "Loading JS entry point from:" << jsPath;
    
    // Read the JavaScript file
    QFile jsFile(jsPath);
    if (!jsFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open JavaScript file:" << jsPath;
        return false;
    }
    
    QTextStream in(&jsFile);
    QString jsCode = in.readAll();
    jsFile.close();
    
    // Just load the JavaScript code directly - let it handle its own requires
    QString wrappedCode = jsCode;
    
    // Set up proper working directory for module resolution
    QString jsDir = QDir(QDir(appDir).absoluteFilePath("../../src/js")).absolutePath();
    qDebug() << "Setting Node.js working directory to:" << jsDir;
    
    // Set up the require function that can load files from disk, then execute our code
    QString setupCode = QString(
        "process.chdir('%1');\n"
        "console.log('Node.js working directory set to:', process.cwd());\n"
        "const publicRequire = require('module').createRequire(process.cwd() + '/');\n"
        "globalThis.require = publicRequire;\n"
        "%2"
    ).arg(jsDir, wrappedCode);
    
    // Use the callback approach to set up proper require function
    try {
        auto loadenv_ret = node::LoadEnvironment(m_env, [&](const node::StartExecutionCallbackInfo& info) -> v8::MaybeLocal<v8::Value> {
            v8::Local<v8::Context> context = m_setup->context();
            v8::Isolate* isolate = context->GetIsolate();
            
            // Use the provided require from the callback info
            v8::Local<v8::Function> require = info.native_require;
            
            // Set up the require function that can load files from disk using provided require
            QString bootstrapCode = QString(
                "(function(require) {\n"
                "  const module = require('%1');\n"
                "  const publicRequire = module.createRequire('%2/');\n"
                "  globalThis.require = publicRequire;\n"
                "  console.log('Bootstrap: require function set up');\n"
                "})"
            ).arg("module", jsDir);
            
            v8::Local<v8::String> bootstrap = v8::String::NewFromUtf8(
                isolate, bootstrapCode.toStdString().c_str(), v8::NewStringType::kNormal
            ).ToLocalChecked();
            
            v8::Local<v8::Script> bootstrapScript;
            if (!v8::Script::Compile(context, bootstrap).ToLocal(&bootstrapScript)) {
                return v8::MaybeLocal<v8::Value>();
            }
            
            v8::Local<v8::Value> bootstrapFunctionResult;
            if (!bootstrapScript->Run(context).ToLocal(&bootstrapFunctionResult)) {
                return v8::MaybeLocal<v8::Value>();
            }
            
            // Call the bootstrap function with require as argument
            v8::Local<v8::Function> bootstrapFunction = bootstrapFunctionResult.As<v8::Function>();
            v8::Local<v8::Value> args[] = { require };
            v8::Local<v8::Value> result;
            if (!bootstrapFunction->Call(context, context->Global(), 1, args).ToLocal(&result)) {
                return v8::MaybeLocal<v8::Value>();
            }
            
            // Now run our actual code
            v8::Local<v8::String> source = v8::String::NewFromUtf8(
                isolate, wrappedCode.toStdString().c_str(), v8::NewStringType::kNormal
            ).ToLocalChecked();
            
            v8::Local<v8::Script> script;
            if (!v8::Script::Compile(context, source).ToLocal(&script)) {
                return v8::MaybeLocal<v8::Value>();
            }
            
            return script->Run(context);
        });
        
        if (loadenv_ret.IsEmpty()) {
            qWarning() << "LoadEnvironment callback failed";
            return false;
        }
        
        // Get reference to handleMessage function
        v8::Local<v8::Context> context = m_setup->context();
        v8::Local<v8::String> handleMessageName = v8::String::NewFromUtf8(
            m_isolate, "handleMessage", v8::NewStringType::kNormal
        ).ToLocalChecked();
        
        v8::Local<v8::Value> handleMessageValue;
        if (!context->Global()->Get(context, handleMessageName).ToLocal(&handleMessageValue) ||
            !handleMessageValue->IsFunction()) {
            qWarning() << "handleMessage function not found or not a function";
            return false;
        }
        
        v8::Local<v8::Function> handleMessageFunc = handleMessageValue.As<v8::Function>();
        m_handleMessageFunction.Reset(m_isolate, handleMessageFunc);
        qDebug() << "handleMessage function loaded successfully";
        
        // Expose callback function to JavaScript
        v8::Local<v8::String> callbackName = v8::String::NewFromUtf8(
            m_isolate, "__nativeCallback", v8::NewStringType::kNormal
        ).ToLocalChecked();
        
        v8::Local<v8::Function> callbackFunc = v8::Function::New(
            context, messageCallback
        ).ToLocalChecked();
        
        context->Global()->Set(context, callbackName, callbackFunc).ToChecked();
        
        return true;
        
    } catch (const std::exception& e) {
        qWarning() << "Failed to load JavaScript:" << e.what();
        return false;
    }
}

void NodeJS::messageCallback(const v8::FunctionCallbackInfo<v8::Value> &args) {
    if (!s_instance || !s_instance->m_currentCallback) {
        return;
    }
    
    v8::Isolate* isolate = args.GetIsolate();
    v8::HandleScope handle_scope(isolate);
    
    if (args.Length() > 0 && args[0]->IsObject()) {
        v8::Local<v8::Context> context = isolate->GetCurrentContext();
        v8::Local<v8::Object> obj = args[0]->ToObject(context).ToLocalChecked();
        
        // Convert V8 object to JSON string
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
        v8::Local<v8::Value> argv[] = { args[0] };
        v8::Local<v8::Value> result;
        if (!stringify->Call(context, json, 1, argv).ToLocal(&result)) {
            return;
        }
        
        v8::String::Utf8Value jsonStr(isolate, result);
        
        // Parse to QJsonObject
        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(QByteArray(*jsonStr), &error);
        
        if (error.error == QJsonParseError::NoError && doc.isObject()) {
            s_instance->m_currentCallback(doc.object());
        }
    }
    
    s_instance->m_currentCallback = nullptr;
}

void NodeJS::msg(const QString &name, const QJsonObject &params, std::function<void(const QJsonObject&)> callback) {
    qDebug() << "msg() called with action:" << name;
    
    if (!m_initialized || !m_isolate || !m_env) {
        qWarning() << "Node.js not initialized";
        callback(QJsonObject{{"status", "error"}, {"message", "Node.js not initialized"}});
        return;
    }
    
    qDebug() << "msg() proceeding with Node.js call";
    m_currentCallback = callback;
    
    v8::Locker locker(m_isolate);
    v8::Isolate::Scope isolate_scope(m_isolate);
    v8::HandleScope handle_scope(m_isolate);
    v8::Context::Scope context_scope(m_setup->context());
    
    v8::Local<v8::Context> context = m_setup->context();
    
    // Create message object with action and data
    QJsonObject jsObject;
    jsObject["action"] = name;
    jsObject["data"] = params;
    
    // Convert QJsonObject to V8 value
    QJsonDocument doc(jsObject);
    QByteArray jsonData = doc.toJson(QJsonDocument::Compact);
    
    v8::Local<v8::String> jsonStr = v8::String::NewFromUtf8(
        m_isolate,
        jsonData.constData(),
        v8::NewStringType::kNormal
    ).ToLocalChecked();
    
    // Parse JSON in V8
    v8::Local<v8::Value> jsonObj;
    if (!context->Global()->Get(context, 
        v8::String::NewFromUtf8(m_isolate, "JSON").ToLocalChecked()).ToLocal(&jsonObj)) {
        callback(QJsonObject{{"status", "error"}, {"message", "Failed to get JSON object"}});
        return;
    }
    
    v8::Local<v8::Object> json = jsonObj->ToObject(context).ToLocalChecked();
    v8::Local<v8::Value> parseFunc;
    if (!json->Get(context, 
        v8::String::NewFromUtf8(m_isolate, "parse").ToLocalChecked()).ToLocal(&parseFunc)) {
        callback(QJsonObject{{"status", "error"}, {"message", "Failed to get JSON.parse"}});
        return;
    }
    
    v8::Local<v8::Function> parse = parseFunc.As<v8::Function>();
    v8::Local<v8::Value> parseArgs[] = { jsonStr };
    v8::Local<v8::Value> jsValue;
    if (!parse->Call(context, json, 1, parseArgs).ToLocal(&jsValue)) {
        callback(QJsonObject{{"status", "error"}, {"message", "Failed to parse JSON"}});
        return;
    }
    
    // Call handleMessage function
    qDebug() << "msg() calling handleMessage function";
    v8::Local<v8::Function> handleMessage = m_handleMessageFunction.Get(m_isolate);
    v8::Local<v8::Value> args[] = { jsValue };
    
    v8::Local<v8::Value> result;
    if (!handleMessage->Call(context, context->Global(), 1, args).ToLocal(&result)) {
        qDebug() << "msg() handleMessage call failed";
        callback(QJsonObject{{"status", "error"}, {"message", "Failed to call handleMessage"}});
        return;
    }
    
    qDebug() << "msg() handleMessage call completed successfully";
}

// QML version with callback
void NodeJS::msg(const QString &name, const QJsonObject &params, const QJSValue &callback) {
    if (callback.isCallable()) {
        msg(name, params, [callback](const QJsonObject& result) mutable {
            // Convert QJsonObject to JSON string and let QML parse it
            QJsonDocument doc(result);
            QString jsonString = doc.toJson(QJsonDocument::Compact);
            
            // Call the JavaScript callback with the JSON string
            QJSValue callResult = callback.call({QJSValue(jsonString)});
            if (callResult.isError()) {
                qWarning() << "JavaScript callback error:" << callResult.toString();
            }
        });
    } else {
        // Fall back to signal if callback is not callable
        msg(name, params);
    }
}

// QML version - emits signal
void NodeJS::msg(const QString &name, const QJsonObject &params) {
    msg(name, params, [this](const QJsonObject& result) {
        emit messageResponse(result);
    });
}

void NodeJS::startEventLoop() {
    qDebug() << "Setting up Qt Timer for Node.js event loop integration";
    
    // Create and configure the event loop timer
    m_eventLoopTimer = new QTimer(this);
    m_eventLoopTimer->setInterval(100); // 100ms interval
    m_eventLoopTimer->setSingleShot(false);
    
    // Connect timer to our event loop processing slot
    connect(m_eventLoopTimer, &QTimer::timeout, this, &NodeJS::spinEventLoop);
    
    // Start the timer
    m_eventLoopTimer->start();
    qDebug() << "Node.js event loop timer started (100ms interval)";
}

void NodeJS::spinEventLoop() {

	qDebug() << "spinEventLoop...";

    if (!m_env || !m_isolate) {
        qDebug() << "spinEventLoop: env or isolate is null, skipping";
        return;
    }
    
    static int callCount = 0;
    callCount++;
    
    // Log every 50 calls (5 seconds at 100ms interval) to avoid spam
    if (callCount % 5 == 1) {
        qDebug() << "spinEventLoop: Processing Node.js event loop (call #" << callCount << ")";
    }
    
    // Process the Node.js event loop
    v8::Locker locker(m_isolate);
    v8::Isolate::Scope isolate_scope(m_isolate);
    v8::HandleScope handle_scope(m_isolate);
    
    // Spin the event loop once to process pending async operations
    auto result = node::SpinEventLoop(m_env);
    qDebug() << "spinEventLoop: SpinEventLoop returned" << (result.IsNothing() ? "nothing" : "a value");
    
    // Check if SpinEventLoop returned something meaningful
    if (result.IsNothing()) {
        if (callCount % 50 == 1) {
            qDebug() << "spinEventLoop: SpinEventLoop returned nothing";
        }
    } else {
        if (callCount % 50 == 1) {
            qDebug() << "spinEventLoop: SpinEventLoop returned value";
        }
    }
}

void NodeJS::stopEventLoop() {
    // Stop the Qt timer first
    if (m_eventLoopTimer) {
        m_eventLoopTimer->stop();
        m_eventLoopTimer->deleteLater();
        m_eventLoopTimer = nullptr;
        qDebug() << "Node.js event loop timer stopped";
    }
    
    // Signal Node.js to stop
    if (m_env) {
        node::Stop(m_env);
    }
}

void NodeJS::shutdown() {
    if (!m_initialized) {
        return;
    }
    
    // Stop the background event loop first
    stopEventLoop();
    
    if (m_isolate) {
        v8::Locker locker(m_isolate);
        v8::Isolate::Scope isolate_scope(m_isolate);
        v8::HandleScope handle_scope(m_isolate);
        
        m_handleMessageFunction.Reset();
    }
    
    m_setup.reset();
    m_initResult.reset();
    
    if (m_platform) {
        v8::V8::Dispose();
        v8::V8::DisposePlatform();
        m_platform.reset();
    }
    
    // Tear down Node.js - should be called once at the end
    static bool tornDown = false;
    if (!tornDown) {
        node::TearDownOncePerProcess();
        tornDown = true;
    }
    
    m_initialized = false;
    qDebug() << "Node.js embedded instance shut down";
}