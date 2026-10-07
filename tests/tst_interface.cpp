#include <QtTest>
#include <QGuiApplication>
#include <QFontDatabase>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QQuickItem>
#include <QQuickTextDocument>
#include <QTextDocument>
#include <QTextCursor>
#include "NotesStore.h"
#include "DocumentHandler.h"

class InterfaceTest:public QObject {
    Q_OBJECT
    NotesStore *notes=nullptr;
    QQmlApplicationEngine *engine=nullptr;
    QQuickWindow *window=nullptr;
    QQuickItem *visualObject(QQuickItem *parent,const QString &name) {
        if(!parent->isVisible())return nullptr;
        if(parent->objectName()==name)return parent;
        for(auto child:parent->childItems())if(auto match=visualObject(child,name))return match;
        return nullptr;
    }
    QObject *object(const char *name) {
        if(auto visible=visualObject(window->contentItem(),QString::fromLatin1(name)))return visible;
        if(auto found=window->findChild<QObject *>(QString::fromLatin1(name)))return found;
        return nullptr;
    }
    void click(const char *name) {
        auto item=qobject_cast<QQuickItem *>(object(name));
        QVERIFY2(item,name);
        QPoint p=item->mapToScene(QPointF(item->width()/2,item->height()/2)).toPoint();
        QTest::mouseMove(window,p);QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,p);QTest::qWait(250);
    }
    void type(const QString &text) { for(auto c:text)QTest::keyClick(window,c.toLatin1());QTest::qWait(100); }
    void snap(const QString &name) { auto dir=qEnvironmentVariable("AURORA_SCREENSHOTS");if(!dir.isEmpty()){QDir().mkpath(dir);QVERIFY(window->grabWindow().save(dir+"/"+name+".png"));} }
private slots:
    void initTestCase() {
        qmlRegisterType<DocumentHandler>("Aurora",1,0,"DocumentHandler");
        notes=new NotesStore(true,this);engine=new QQmlApplicationEngine(this);
        engine->rootContext()->setContextProperty("notes",notes);
        engine->load(QUrl("qrc:/qml/AppShell.qml"));
        QVERIFY(!engine->rootObjects().isEmpty());
        window=qobject_cast<QQuickWindow *>(engine->rootObjects().first());QVERIFY(window);
        window->resize(1440,900);window->requestActivate();QTest::qWait(600);
    }
    void benchmarkFlow() {
        QCOMPARE(notes->workspace(),QString("Design")); QCOMPARE(notes->noteCount(),7);snap("01-dark-desktop");
        click("navPersonal");QCOMPARE(notes->workspace(),QString("Personal"));
        click("navResearch");QCOMPARE(notes->workspace(),QString("Research"));
        click("navDesign");QCOMPARE(notes->workspace(),QString("Design"));
        click("noteRow_landing-page");QCOMPARE(notes->title(),QString("Landing Page Ideas"));
        click("noteRow_typography");QCOMPARE(notes->title(),QString("Typography Notes"));
        click("noteRow_visual-rhythm");QCOMPARE(notes->title(),QString("Visual Rhythm"));
        click("searchField");type("type");QCOMPARE(notes->noteCount(),1);snap("02-search");
        QTest::keyClick(window,Qt::Key_A,Qt::ControlModifier);QTest::keyClick(window,Qt::Key_Backspace);QTest::qWait(200);QCOMPARE(notes->noteCount(),7);
        QTest::keyClick(window,Qt::Key_N,Qt::ControlModifier);QTest::qWait(300);QCOMPARE(notes->noteCount(),8);
        QVERIFY(object("editorTitle")->property("activeFocus").toBool());
        type("A Quiet Interface");QCOMPARE(notes->title(),QString("A Quiet Interface"));
        QTest::keyClick(window,Qt::Key_Return);type("Small details make a thoughtful space.");QVERIFY(notes->body().contains("Small details"));snap("03-new-note");
        notes->selectNote("visual-rhythm");QTest::qWait(220);
        auto body=object("editorBody");QVERIFY(body);
        auto doc=body->property("textDocument").value<QQuickTextDocument *>()->textDocument();
        int start=doc->toPlainText().indexOf("Good interfaces");QVERIFY(start>=0);
        QMetaObject::invokeMethod(body,"select",Q_ARG(int,start),Q_ARG(int,start+15));QTest::qWait(220);
        QVERIFY(object("selectionToolbar")->property("shown").toBool());snap("04-selection");
        click("selectionBoldButton");QTextCursor c(doc);c.setPosition(start+2);QVERIFY(c.charFormat().fontWeight()>=QFont::Bold);
        QTest::keyClick(window,Qt::Key_K,Qt::ControlModifier);QTest::qWait(250);
        QVERIFY(object("commandPalette")->property("opened").toBool());snap("05-command-palette");
        type("toggle sidebar");QTest::keyClick(window,Qt::Key_Return);QTest::qWait(300);QVERIFY(!window->property("sidebarVisible").toBool());
        window->resize(900,650);QTest::qWait(300);click("toggleSidebarButton");QVERIFY(window->property("sidebarVisible").toBool());snap("06-narrow-expanded");
        window->resize(760,650);window->setProperty("sidebarMode",0);window->setProperty("listMode",0);QTest::qWait(300);QVERIFY(!window->property("listVisible").toBool());snap("07-compact");
        QTest::keyClick(window,Qt::Key_F,Qt::ControlModifier);QTest::qWait(250);
        QVERIFY(object("noteDrawer")->property("opened").toBool());
        type("type");QCOMPARE(notes->noteCount(),1);snap("07b-compact-search");
        notes->setQuery("");QMetaObject::invokeMethod(object("noteDrawer"),"close");QTest::qWait(180);
        QTest::keyClick(window,Qt::Key_Comma,Qt::ControlModifier);QTest::qWait(250);QVERIFY(object("settingsDialog")->property("opened").toBool());snap("08-settings-dark");
        click("themeLight");QTest::qWait(300);snap("09-settings-light");
        click("settingsTabEditor");auto slider=object("fontSizeSlider");QVERIFY(slider);slider->setProperty("value",18.0);QMetaObject::invokeMethod(slider,"moved");QTest::qWait(300);snap("10-editor-settings");
        QMetaObject::invokeMethod(object("settingsDialog"),"close");QTest::qWait(300);
        window->resize(1440,900);window->setProperty("sidebarMode",0);window->setProperty("listMode",0);QTest::qWait(300);snap("11-light-desktop");
        auto id=notes->selectedId();QMetaObject::invokeMethod(window,"requestArchive",Q_ARG(QVariant,id));QTest::qWait(300);QVERIFY(notes->selectedId()!=id);QVERIFY(object("toast")->property("showing").toBool());snap("12-archived-toast");
        notes->setWorkspace("Archive");QCOMPARE(notes->noteCount(),1);notes->restoreNote(id);QCOMPARE(notes->noteCount(),0);
        notes->setWorkspace("Design");notes->selectNote("visual-rhythm");QTest::qWait(200);
        QMetaObject::invokeMethod(window,"executeCommand",Q_ARG(QVariant,"theme"));QTest::qWait(350);snap("13-final-dark");
    }
    void cleanupTestCase() { delete engine; engine=nullptr; delete notes; notes=nullptr; }
};
int main(int argc,char **argv) {
    QGuiApplication app(argc,argv);
    app.setOrganizationName("Aurora QA");app.setApplicationName("Aurora Interface Tests");
    for(const auto &file:QDir(":/fonts").entryList({"*.ttf"},QDir::Files))QFontDatabase::addApplicationFont(":/fonts/"+file);
    InterfaceTest test;return QTest::qExec(&test,argc,argv);
}
#include "tst_interface.moc"
