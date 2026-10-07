#pragma once
#include <QAbstractListModel>
#include <QDateTime>
#include <QTimer>
#include <QVariantMap>

struct Note {
    QString id, title, body, workspace, edited;
    QStringList tags;
    bool favorite = false, archived = false;
    qint64 order = 0;
};

class NotesStore : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QAbstractItemModel* model READ model CONSTANT)
    Q_PROPERTY(QString workspace READ workspace WRITE setWorkspace NOTIFY workspaceChanged)
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(QString sortMode READ sortMode WRITE setSortMode NOTIFY filterChanged)
    Q_PROPERTY(bool favoritesOnly READ favoritesOnly WRITE setFavoritesOnly NOTIFY filterChanged)
    Q_PROPERTY(QString selectedId READ selectedId NOTIFY selectedNoteChanged)
    Q_PROPERTY(QString title READ title WRITE renameSelected NOTIFY selectedNoteChanged)
    Q_PROPERTY(QString body READ body NOTIFY selectedNoteChanged)
    Q_PROPERTY(QString editedLabel READ editedLabel NOTIFY selectedNoteChanged)
    Q_PROPERTY(QString selectedWorkspace READ selectedWorkspace NOTIFY selectedNoteChanged)
    Q_PROPERTY(bool favorite READ favorite NOTIFY selectedNoteChanged)
    Q_PROPERTY(bool hasSelection READ hasSelection NOTIFY selectedNoteChanged)
    Q_PROPERTY(int wordCount READ wordCount NOTIFY selectedNoteChanged)
    Q_PROPERTY(QStringList tags READ tags NOTIFY selectedNoteChanged)
    Q_PROPERTY(int noteCount READ noteCount NOTIFY countsChanged)
    Q_PROPERTY(QVariantMap counts READ counts NOTIFY countsChanged)
    Q_PROPERTY(QString saveStatus READ saveStatus NOTIFY saveStatusChanged)
    Q_PROPERTY(bool autosave READ autosave WRITE setAutosave NOTIFY preferencesChanged)
    Q_PROPERTY(bool rememberWorkspace READ rememberWorkspace WRITE setRememberWorkspace NOTIFY preferencesChanged)
public:
    enum Roles { IdRole = Qt::UserRole + 1, TitleRole, PreviewRole, EditedRole, FavoriteRole, WorkspaceRole };
    explicit NotesStore(bool demo, QObject *parent = nullptr, const QString &storagePath = {});
    QAbstractItemModel *model() { return this; }
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &, int role) const override;
    QHash<int,QByteArray> roleNames() const override;
    QString workspace() const { return m_workspace; }
    QString query() const { return m_query; }
    QString sortMode() const { return m_sort; }
    bool favoritesOnly() const { return m_favoritesOnly; }
    QString selectedId() const { return m_selected; }
    QString title() const;
    QString body() const;
    QString editedLabel() const;
    QString selectedWorkspace() const;
    bool favorite() const;
    bool hasSelection() const { return selected() != nullptr; }
    int wordCount() const;
    QStringList tags() const;
    int noteCount() const { return m_rows.size(); }
    QVariantMap counts() const;
    QString saveStatus() const { return m_saveStatus; }
    bool autosave() const { return m_autosave; }
    bool rememberWorkspace() const { return m_remember; }
    void setWorkspace(const QString &);
    void setQuery(const QString &);
    void setSortMode(const QString &);
    void setFavoritesOnly(bool);
    void setAutosave(bool);
    void setRememberWorkspace(bool);
    Q_INVOKABLE void selectNote(const QString &id);
    Q_INVOKABLE void createNote();
    Q_INVOKABLE void renameNote(const QString &id, const QString &title);
    Q_INVOKABLE void renameSelected(const QString &title);
    Q_INVOKABLE void updateBody(const QString &html);
    Q_INVOKABLE void toggleFavorite();
    Q_INVOKABLE void toggleFavoriteFor(const QString &id);
    Q_INVOKABLE void duplicateNote(const QString &id);
    Q_INVOKABLE void archiveNote(const QString &id);
    Q_INVOKABLE void restoreNote(const QString &id);
    Q_INVOKABLE void moveNote(const QString &id, const QString &workspace);
    Q_INVOKABLE void copyNote();
    Q_INVOKABLE bool exportNote(const QUrl &url);
    Q_INVOKABLE void save();
signals:
    void workspaceChanged();
    void queryChanged();
    void filterChanged();
    void selectedNoteChanged();
    void countsChanged();
    void saveStatusChanged();
    void preferencesChanged();
    void errorOccurred(const QString &message);
private:
    Note *find(const QString &id);
    const Note *selected() const;
    Note *selected();
    void rebuild(bool ensureSelection = true);
    void touch(Note &note);
    void notifyRow(const QString &id);
    void refreshOrdering();
    void scheduleSave();
    void seed();
    bool load();
    QVector<Note> m_notes;
    QVector<int> m_rows;
    QString m_workspace = "Design", m_query, m_selected, m_sort = "edited", m_saveStatus = "Saved locally";
    bool m_favoritesOnly = false, m_demo = false, m_autosave = true, m_remember = true;
    QTimer m_saveTimer;
    QString m_path;
};
