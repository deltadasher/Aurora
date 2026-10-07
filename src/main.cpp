#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTimer>
#include <QDir>
#include <QFontDatabase>
#include <QCommandLineParser>
#include <QRegularExpression>
#include "NotesStore.h"
#include "DocumentHandler.h"

int main(int argc,char **argv) {
    QGuiApplication app(argc,argv);
    app.setOrganizationName("Aurora"); app.setApplicationName("Aurora Notes"); app.setApplicationVersion("1.0.0");
    QCommandLineParser parser;parser.setApplicationDescription("A quiet place for your thoughts. Native Qt Quick notes.");parser.addHelpOption();parser.addVersionOption();
    parser.addOption({"demo","Start with demo notes without reading or writing saved notes."});
    parser.addOption({"snapshot","Save a rendered window PNG and exit.","path"});
    parser.addOption({"size","Initial window size, for example 1440x900.","size","1440x900"});
    parser.addOption({"light","Start in the light theme."});
    parser.addOption({"settings","Open settings at launch."});
    parser.addOption({"palette","Open the command palette at launch."});
    parser.process(app);
    for(const auto &file:QDir(":/fonts").entryList({"*.ttf"},QDir::Files))QFontDatabase::addApplicationFont(":/fonts/"+file);
    qmlRegisterType<DocumentHandler>("Aurora",1,0,"DocumentHandler");
    NotesStore notes(parser.isSet("demo"));
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("notes",&notes);
    engine.load(QUrl("qrc:/qml/AppShell.qml"));
    if(engine.rootObjects().isEmpty())return 1;
    auto window=qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    auto size=parser.value("size").split('x');if(size.size()==2)window->resize(size[0].toInt(),size[1].toInt());
    if(parser.isSet("light"))QMetaObject::invokeMethod(window,"executeCommand",Q_ARG(QVariant,"light"));
    if(parser.isSet("settings"))QMetaObject::invokeMethod(window,"executeCommand",Q_ARG(QVariant,"settings"));
    if(parser.isSet("palette")){auto palette=window->findChild<QObject *>("commandPalette");if(palette)QMetaObject::invokeMethod(palette,"open");}
    if(parser.isSet("snapshot")) {
        QTimer::singleShot(1100,&app,[&]{ auto path=parser.value("snapshot");QDir().mkpath(QFileInfo(path).absolutePath());auto image=window->grabWindow();if(image.isNull()||!image.save(path)){qWarning("Could not capture the rendered window");app.exit(2);}else app.exit(0); });
    }
    return app.exec();
}
