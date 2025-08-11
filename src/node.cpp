#include "include/node.h"

#include <QCoreApplication>
#include <QDebug>
#include <QMutexLocker>

NodeJS::NodeJS(QObject *parent) : QObject(parent), m_initState(InitState::NotInitialized) {}

NodeJS::~NodeJS() {
 shutdown();
}

bool NodeJS::initialize() {
 {
		QMutexLocker locker(&m_initMutex);
		if (m_initState == InitState::Initialized) {
			qDebug() << "Node.js already initialized";
			return true;
		}
		if (m_initState == InitState::Initializing) {
			qDebug() << "Node.js initialization already in progress";
			return false;
		}
		m_initState = InitState::Initializing;
 }

 qDebug() << "NodeJS: Initializing with NodeThread";

 m_nodeThread = std::make_unique<NodeThread>(this);

 connect(m_nodeThread.get(), &NodeThread::initializationFailed, this, [this](const QString &error) {
		qCritical() << "Critical Node.js failure:" << error;

		// Update state and wake up waiting threads
		{
			QMutexLocker locker(&m_initMutex);
			m_initState = InitState::Failed;
			m_initCondition.wakeAll();
		}

		QCoreApplication::exit(1);
 });

 if (!m_nodeThread->initialize()) {
		qWarning() << "NodeJS: Failed to initialize NodeThread";

		// Update state and wake up waiting threads
		{
			QMutexLocker locker(&m_initMutex);
			m_initState = InitState::Failed;
			m_initCondition.wakeAll();
		}

		return false;
 }

 // Initialization successful
 {
		QMutexLocker locker(&m_initMutex);
		m_initState = InitState::Initialized;
		m_initCondition.wakeAll();
 }

 qDebug() << "NodeJS: Initialization completed successfully";
 return true;
}

void NodeJS::shutdown() {
 {
		QMutexLocker locker(&m_initMutex);
		if (m_initState != InitState::Initialized) {
			return;
		}
 }

 qDebug() << "NodeJS: Shutting down";

 if (m_nodeThread) {
		m_nodeThread->shutdown();
		m_nodeThread.reset();
 }

 {
		QMutexLocker locker(&m_initMutex);
		m_initState = InitState::NotInitialized;
 }

 qDebug() << "NodeJS: Shutdown completed";
}

void NodeJS::msg(const QString &name, const QJsonObject &params, std::function<void(const QJsonObject &)> callback) {
 qDebug() << "NodeJS::msg() called with action:" << name;

 // Wait for initialization to complete or fail
 {
		QMutexLocker locker(&m_initMutex);
		while (m_initState == InitState::NotInitialized || m_initState == InitState::Initializing) {
			qDebug() << "NodeJS::msg() waiting for initialization to complete...";
			m_initCondition.wait(&m_initMutex);
		}

		if (m_initState == InitState::Failed) {
			qWarning() << "NodeJS: Initialization failed, cannot process message";
			callback(QJsonObject{{"status", "error"}, {"message", "Node.js initialization failed"}});
			return;
		}
 }

 if (!m_nodeThread) {
		qWarning() << "NodeJS: NodeThread is null after initialization";
		callback(QJsonObject{{"status", "error"}, {"message", "Node.js thread unavailable"}});
		return;
 }

 m_nodeThread->sendMessage(name, params, callback);
}

void NodeJS::msg(const QString &name, const QJsonObject &params, const QJSValue &callback) {
 if (callback.isCallable()) {
		msg(name, params, [callback](const QJsonObject &result) mutable {
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
 msg(name, params, [this](const QJsonObject &result) { emit messageResponse(result); });
}
