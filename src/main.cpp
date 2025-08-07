#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml>

#include "include/systemmanager.h"
#include "include/wifimanager.h"
#include "include/node.h"

int main(int argc, char *argv[]) {
 // Setup arguments for Node.js FIRST - before Qt
 argv = uv_setup_args(argc, argv);
 
 QGuiApplication app(argc, argv);
 app.setApplicationName("Matchbox Wallet");
 app.setApplicationVersion("0.0.1");
 app.setOrganizationName("LiberSoft");

 // Set application icon
 app.setWindowIcon(QIcon(":/WalletModule/src/img/wallet.svg"));

 // Create global instances for context properties
 SystemManager *systemManager = new SystemManager();
 WiFiManager *wifiManager = new WiFiManager();
 NodeJS *nodeJS = new NodeJS();

 QQmlApplicationEngine engine;

 // Initialize Node.js
 if (!nodeJS->initialize()) {
  qWarning() << "Failed to initialize Node.js embedding";
 } else {
  // Test the Node.js integration
  nodeJS->msg("ping", QJsonObject(), [](const QJsonObject& result) {
   qDebug() << "Node.js response:" << QJsonDocument(result).toJson(QJsonDocument::Compact);
  });
 }
 
 // Register context properties instead of QML types
 engine.rootContext()->setContextProperty("SystemManager", systemManager);
 engine.rootContext()->setContextProperty("WiFiManager", wifiManager);
 engine.rootContext()->setContextProperty("NodeJS", nodeJS);
 engine.rootContext()->setContextProperty("applicationVersion", app.applicationVersion());
 const QUrl url(QStringLiteral("qrc:/WalletModule/src/qml/main.qml"));
 QObject::connect(
					&engine, &QQmlApplicationEngine::objectCreated, &app,
					[url](QObject *obj, const QUrl &objUrl) {
						if (!obj && url == objUrl) QCoreApplication::exit(-1);
					},
					Qt::QueuedConnection);
 engine.load(url);
 return app.exec();
}
