#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "rkupgradetool.h"
int main(int argc, char *argv[])
{
    // qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));

    QCoreApplication::setOrganizationName("expample");
    QCoreApplication::setOrganizationDomain("rkupgrade.tool");
    QCoreApplication::setApplicationName("RkUpgradeTool");

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    qmlRegisterSingletonType<RkUpgradeTool>("com.expample.rkupgradetool", 1, 0, "RkUpTool", RkUpgradeTool::instance);
    qmlRegisterSingletonType(QUrl("qrc:/AppState.qml"), "App", 1, 0, "AppState");

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
