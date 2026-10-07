#include "NotesStore.h"
#include <QFile>
#include <QSignalSpy>
#include <QStandardPaths>
#include <QTemporaryDir>
#include <QtTest>

class NotesStoreTest : public QObject {
    Q_OBJECT

    static QString rowId(const NotesStore &store, int row) {
        return store.data(store.index(row, 0), NotesStore::IdRole).toString();
    }
    static bool contains(const NotesStore &store, const QString &id) {
        for (int row = 0; row < store.rowCount(); ++row)
            if (rowId(store, row) == id) return true;
        return false;
    }

private slots:
    void initTestCase() {
        QCoreApplication::setOrganizationName("AuroraNotesTests");
        QCoreApplication::setApplicationName("AuroraNotesTests");
        QStandardPaths::setTestModeEnabled(true);
    }

    void seededWorkspaceAndSearch() {
        NotesStore store(true);
        QCOMPARE(store.workspace(), QString("Design"));
        QCOMPARE(store.rowCount(), 7);
        QCOMPARE(store.noteCount(), 7);
        QCOMPARE(store.counts().value("Design").toInt(), 7);
        QCOMPARE(store.counts().value("All Notes").toInt(), 16);
        QCOMPARE(store.selectedId(), QString("visual-rhythm"));
        QCOMPARE(store.title(), QString("Visual Rhythm"));
        QVERIFY(store.body().contains("Good interfaces rarely feel evenly spaced."));

        store.setQuery("type");
        QCOMPARE(store.rowCount(), 1);
        QCOMPARE(rowId(store, 0), QString("typography"));
        // Search keeps the current document open while narrowing the list.
        QCOMPARE(store.selectedId(), QString("visual-rhythm"));
        store.setQuery("");
        QCOMPARE(store.rowCount(), 7);
        QVERIFY(contains(store, "visual-rhythm"));

        store.setQuery("no note contains this phrase");
        QCOMPARE(store.rowCount(), 0);
        QVERIFY(store.hasSelection());
        store.setQuery("");
        QCOMPARE(store.rowCount(), 7);
    }

    void creatingClearsFiltersAndRestoresSiblings() {
        NotesStore store(true);
        store.setQuery("type");
        store.setFavoritesOnly(true);
        QCOMPARE(store.rowCount(), 1);
        store.createNote();
        QCOMPARE(store.query(), QString());
        QVERIFY(!store.favoritesOnly());
        QCOMPARE(store.rowCount(), 8);
        QCOMPARE(store.noteCount(), 8);
        QCOMPARE(store.counts().value("Design").toInt(), 8);
        QCOMPARE(rowId(store, 0), store.selectedId());
        QVERIFY(store.selectedId() != "visual-rhythm");
        QVERIFY(store.title().isEmpty());
        QVERIFY(store.body().isEmpty());
        QCOMPARE(store.data(store.index(0, 0), NotesStore::TitleRole).toString(), QString("Untitled"));
        QVERIFY(contains(store, "landing-page"));
        QVERIFY(contains(store, "color"));
    }

    void editAndDuplicate() {
        NotesStore store(true);
        store.createNote();
        const QString source = store.selectedId();
        store.renameSelected("New field notes");
        const QString body = "<h1>Signal</h1><p>A useful new thought.</p>";
        store.updateBody(body);
        QCOMPARE(store.title(), QString("New field notes"));
        QCOMPARE(store.body(), body);
        QCOMPARE(store.wordCount(), 5);
        QCOMPARE(store.editedLabel(), QString("Edited just now"));

        store.duplicateNote(source);
        QCOMPARE(store.rowCount(), 9);
        QVERIFY(store.selectedId() != source);
        QCOMPARE(store.title(), QString("New field notes — copy"));
        QCOMPARE(store.body(), body);
        QCOMPARE(store.selectedWorkspace(), QString("Design"));
        QVERIFY(contains(store, source));
        store.selectNote(source);
        QCOMPARE(store.title(), QString("New field notes"));
    }

    void favoriteFiltering() {
        NotesStore store(true);
        store.setFavoritesOnly(true);
        QCOMPARE(store.rowCount(), 3);
        QVERIFY(contains(store, "visual-rhythm"));
        QVERIFY(!contains(store, "landing-page"));
        store.toggleFavoriteFor("landing-page");
        QCOMPARE(store.rowCount(), 4);
        QVERIFY(contains(store, "landing-page"));
        store.toggleFavoriteFor("visual-rhythm");
        QCOMPARE(store.rowCount(), 3);
        QVERIFY(!contains(store, "visual-rhythm"));
        QVERIFY(store.hasSelection());
        QVERIFY(contains(store, store.selectedId()));
        store.setFavoritesOnly(false);
        QCOMPARE(store.rowCount(), 7);
        store.selectNote("landing-page");
        QVERIFY(store.favorite());
    }

    void moveArchiveAndRestore() {
        NotesStore store(true);
        store.moveNote("landing-page", "Research");
        QCOMPARE(store.rowCount(), 6);
        QCOMPARE(store.counts().value("Design").toInt(), 6);
        QCOMPARE(store.counts().value("Research").toInt(), 4);
        QVERIFY(!contains(store, "landing-page"));
        store.setWorkspace("Research");
        QCOMPARE(store.rowCount(), 4);
        QVERIFY(contains(store, "landing-page"));
        store.selectNote("landing-page");
        QCOMPARE(store.selectedWorkspace(), QString("Research"));
        store.archiveNote("landing-page");
        QCOMPARE(store.rowCount(), 3);
        QCOMPARE(store.counts().value("Archive").toInt(), 1);
        QVERIFY(!contains(store, "landing-page"));
        QVERIFY(store.selectedId() != "landing-page");
        store.setWorkspace("Archive");
        QCOMPARE(store.rowCount(), 1);
        QCOMPARE(store.selectedId(), QString("landing-page"));
        store.restoreNote("landing-page");
        QCOMPARE(store.rowCount(), 0);
        QVERIFY(!store.hasSelection());
        QCOMPARE(store.counts().value("Archive").toInt(), 0);
        store.setWorkspace("Research");
        QCOMPARE(store.rowCount(), 4);
        QVERIFY(contains(store, "landing-page"));
    }

    void markdownExport() {
        NotesStore store(true);
        store.createNote();
        store.renameSelected("Field notes");
        store.updateBody("<p>A <strong>clear</strong> thought.</p><ul><li>First idea</li><li>Second idea</li></ul>");
        QTemporaryDir directory;
        QVERIFY(directory.isValid());
        const QString path = directory.filePath("field-notes.md");
        QVERIFY(store.exportNote(QUrl::fromLocalFile(path)));
        QFile file(path);
        QVERIFY(file.open(QIODevice::ReadOnly));
        const QString markdown = QString::fromUtf8(file.readAll());
        QVERIFY(markdown.startsWith("# Field notes\n\n"));
        QVERIFY(markdown.contains("**clear**"));
        QVERIFY(markdown.contains("First idea"));
        QVERIFY(markdown.contains("Second idea"));
        QVERIFY(!markdown.contains("<p>"));
        QSignalSpy errors(&store, &NotesStore::errorOccurred);
        QVERIFY(!store.exportNote(QUrl::fromLocalFile(directory.filePath("missing/note.md"))));
        QCOMPARE(errors.count(), 1);
    }

    void sortingTracksEdits() {
        NotesStore alphabetical(true);
        alphabetical.setSortMode("title");
        alphabetical.renameNote("visual-rhythm", "A quiet index");
        QCOMPARE(rowId(alphabetical, 0), QString("visual-rhythm"));
        alphabetical.renameNote("visual-rhythm", "Zzz final thought");
        QCOMPARE(rowId(alphabetical, alphabetical.rowCount() - 1), QString("visual-rhythm"));
        QCOMPARE(alphabetical.selectedId(), QString("visual-rhythm"));

        NotesStore recentlyEdited(true);
        recentlyEdited.selectNote("color");
        recentlyEdited.updateBody("<p>Updated color palette.</p>");
        QCOMPARE(rowId(recentlyEdited, 0), QString("color"));
        QCOMPARE(recentlyEdited.selectedId(), QString("color"));
    }

    void persistenceRoundTrip() {
        QTemporaryDir directory;
        QVERIFY(directory.isValid());
        const auto path = directory.filePath("notes.json");
        NotesStore writer(false, nullptr, path);
        writer.setRememberWorkspace(false);
        writer.setWorkspace("Design");
        writer.createNote();
        const auto id = writer.selectedId();
        writer.renameSelected("Saved field notes");
        writer.updateBody("<p>A thought worth keeping.</p>");
        writer.toggleFavorite();
        writer.archiveNote("color");
        writer.save();
        QCOMPARE(writer.saveStatus(), QString("Saved locally"));
        QVERIFY(QFile::exists(path));

        NotesStore reader(false, nullptr, path);
        reader.setWorkspace("Design");
        reader.selectNote(id);
        QCOMPARE(reader.title(), QString("Saved field notes"));
        QCOMPARE(reader.body(), QString("<p>A thought worth keeping.</p>"));
        QVERIFY(reader.favorite());
        QCOMPARE(reader.counts().value("Archive").toInt(), 1);
        QCOMPARE(reader.counts().value("All Notes").toInt(), 16);
    }
};

QTEST_MAIN(NotesStoreTest)
#include "tst_notesstore.moc"
