// #include <FelgoHotReload>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml>

// Added for environment/platform setup
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>

#include "include/node.h"

int main(int argc, char *argv[]) {
 // Setup arguments for Node.js FIRST - before Qt
 argv = uv_setup_args(argc, argv);

 // Platform and environment setup (moved from start.sh)
 auto exists = [](const char *p) { return QFile::exists(QString::fromUtf8(p)); };
 auto cmdOk = [](const QString &cmd) {
		QProcess p;
		p.start("sh", {"-lc", cmd});
		if (!p.waitForStarted(1000)) return false;
		if (!p.waitForFinished(1500)) return false;
		return p.exitStatus() == QProcess::NormalExit && p.exitCode() == 0;
 };
 if (!qgetenv("DISPLAY").isEmpty() && cmdOk("command -v xset >/dev/null 2>&1 && xset q >/dev/null 2>&1")) {
		qputenv("QT_QPA_PLATFORM", "xcb");
		qInfo() << "Using X11 (xcb) platform";
 } else if (!qgetenv("WAYLAND_DISPLAY").isEmpty() && !qgetenv("XDG_RUNTIME_DIR").isEmpty()) {
		qputenv("QT_QPA_PLATFORM", "wayland");
		qInfo() << "Using Wayland platform";
 } else if (exists("/dev/dri/card0")) {
		qputenv("QT_QPA_PLATFORM", "eglfs");
		qputenv("QT_QPA_EGLFS_HIDECURSOR", "1");
		qInfo() << "Using EGLFS (DRM/KMS) platform";
 } else if (exists("/dev/fb0") || exists("/dev/fb")) {
		qputenv("QT_QPA_PLATFORM", "linuxfb");
		qputenv("QT_QPA_FB", "/dev/fb0");
		qInfo() << "Using Linux Framebuffer (console mode)";
 } else {
		qputenv("QT_QPA_PLATFORM", "xcb");
		qInfo() << "No display detected, trying X11 (xcb) as fallback";
 }

 // Allow QML XMLHttpRequest to read from file:// for translations
 qputenv("QML_XHR_ALLOW_FILE_READ", "1");

 QGuiApplication app(argc, argv);
 app.setApplicationName("Matchbox Wallet");
 app.setApplicationVersion("0.0.1");
 app.setOrganizationName("LiberSoft");

 // Ensure working directory is the binary directory
 QDir::setCurrent(QCoreApplication::applicationDirPath());

 // Set application icon
 app.setWindowIcon(QIcon(":/WalletModule/src/img/wallet.svg"));

 // Create global instances for context properties
 NodeJS *nodeJS = new NodeJS();

 QQmlApplicationEngine engine;

 // Initialize Node.js
 if (!nodeJS->initialize()) {
		qWarning() << "Failed to initialize Node.js embedding";
 } else {
		qDebug() << "Node.js initialization completed successfully";
 }

 // Register context properties instead of QML types
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
