#include "NotesStore.h"
#include <QClipboard>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSettings>
#include <QStandardPaths>
#include <QTextDocument>
#include <QUuid>
#include <algorithm>

static QString plain(const QString &html) { QTextDocument d; d.setHtml(html); return d.toPlainText(); }
NotesStore::NotesStore(bool demo, QObject *parent, const QString &storagePath) : QAbstractListModel(parent), m_demo(demo) {
    m_path = storagePath.isEmpty() ? QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/notes.json" : storagePath;
    QSettings s;
    if (!demo && s.value("Appearance/openLastWorkspace", true).toBool())
        m_workspace = s.value("lastWorkspace", "Design").toString();
    if (demo || !load()) seed();
    m_saveTimer.setInterval(450); m_saveTimer.setSingleShot(true);
    connect(&m_saveTimer, &QTimer::timeout, this, &NotesStore::save);
    rebuild();
}
int NotesStore::rowCount(const QModelIndex &parent) const { return parent.isValid() ? 0 : m_rows.size(); }
QVariant NotesStore::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_rows.size()) return {};
    const auto &n = m_notes[m_rows[index.row()]];
    switch(role) {
    case IdRole: return n.id;
    case TitleRole: return n.title.isEmpty() ? "Untitled" : n.title;
    case PreviewRole: {
        QString text = plain(n.body).simplified();
        if (text.startsWith(n.title)) text = text.mid(n.title.size()).trimmed();
        return text.isEmpty() ? "A little space for your next idea." : text.left(200);
    }
    case EditedRole: return n.edited;
    case FavoriteRole: return n.favorite;
    case WorkspaceRole: return n.workspace;
    }
    return {};
}
QHash<int,QByteArray> NotesStore::roleNames() const {
    return {{IdRole,"noteId"},{TitleRole,"title"},{PreviewRole,"preview"},{EditedRole,"edited"},{FavoriteRole,"favorite"},{WorkspaceRole,"workspaceName"}};
}
Note *NotesStore::find(const QString &id) { for(auto &n:m_notes) if(n.id == id) return &n; return nullptr; }
Note *NotesStore::selected() { return find(m_selected); }
const Note *NotesStore::selected() const { for(const auto &n:m_notes) if(n.id==m_selected) return &n; return nullptr; }
QString NotesStore::title() const { auto n=selected(); return n?n->title:QString(); }
QString NotesStore::body() const { auto n=selected(); return n?n->body:QString(); }
QString NotesStore::editedLabel() const { auto n=selected(); return n?"Edited "+n->edited:QString(); }
QString NotesStore::selectedWorkspace() const { auto n=selected(); return n?n->workspace:QString(); }
bool NotesStore::favorite() const { auto n=selected(); return n&&n->favorite; }
QStringList NotesStore::tags() const { auto n=selected(); return n?n->tags:QStringList(); }
int NotesStore::wordCount() const { return plain(body()).split(QRegularExpression("\\s+"),Qt::SkipEmptyParts).size(); }
QVariantMap NotesStore::counts() const {
    QVariantMap result{{"Personal",0},{"Design",0},{"Research",0},{"Ideas",0},{"All Notes",0},{"Favorites",0},{"Recent",0},{"Archive",0}};
    for(const auto &n:m_notes) {
        if(n.archived) { result["Archive"] = result["Archive"].toInt()+1; continue; }
        result[n.workspace]=result[n.workspace].toInt()+1;
        result["All Notes"]=result["All Notes"].toInt()+1;
        result["Recent"]=result["Recent"].toInt()+1;
        if(n.favorite) result["Favorites"]=result["Favorites"].toInt()+1;
    }
    return result;
}
void NotesStore::rebuild(bool ensureSelection) {
    beginResetModel(); m_rows.clear();
    for(int i=0;i<m_notes.size();++i) {
        const auto &n=m_notes[i];
        bool accept = m_workspace=="Archive" ? n.archived : !n.archived;
        if(m_workspace=="Favorites") accept &= n.favorite;
        else if(m_workspace!="Archive" && m_workspace!="All Notes" && m_workspace!="Recent") accept &= n.workspace==m_workspace;
        if(m_favoritesOnly) accept &= n.favorite;
        if(!m_query.isEmpty()) accept &= (n.title.contains(m_query,Qt::CaseInsensitive) || plain(n.body).contains(m_query,Qt::CaseInsensitive));
        if(accept) m_rows.append(i);
    }
    std::stable_sort(m_rows.begin(),m_rows.end(),[this](int a,int b){ return m_sort=="title" ? m_notes[a].title.localeAwareCompare(m_notes[b].title)<0 : m_notes[a].order>m_notes[b].order; });
    endResetModel();
    if(ensureSelection) {
        bool visible=false; for(int i:m_rows) if(m_notes[i].id==m_selected) visible=true;
        if(!visible) m_selected=m_rows.isEmpty()?QString():m_notes[m_rows.first()].id;
    }
    emit countsChanged(); emit selectedNoteChanged();
}
void NotesStore::setWorkspace(const QString &value) {
    if(m_workspace==value) return;
    m_workspace=value; m_query.clear(); m_favoritesOnly=false;
    rebuild(); emit workspaceChanged(); emit queryChanged(); emit filterChanged();
    if(m_remember && !m_demo) QSettings().setValue("lastWorkspace",value);
}
void NotesStore::setQuery(const QString &value) { if(m_query==value)return; m_query=value; rebuild(false); emit queryChanged(); }
void NotesStore::setSortMode(const QString &value) { if(m_sort==value)return; m_sort=value; rebuild(false); emit filterChanged(); }
void NotesStore::setFavoritesOnly(bool value) { if(m_favoritesOnly==value)return; m_favoritesOnly=value; rebuild(false); emit filterChanged(); }
void NotesStore::setAutosave(bool value) { m_autosave=value; if(value && m_saveStatus=="Unsaved changes") scheduleSave(); emit preferencesChanged(); }
void NotesStore::setRememberWorkspace(bool value) { m_remember=value; emit preferencesChanged(); }
void NotesStore::selectNote(const QString &id) { if(!find(id)||m_selected==id)return; m_selected=id; emit selectedNoteChanged(); }
void NotesStore::notifyRow(const QString &id) { for(int r=0;r<m_rows.size();++r) if(m_notes[m_rows[r]].id==id) emit dataChanged(index(r),index(r)); }
void NotesStore::refreshOrdering() {
    auto sorted=m_rows;
    std::stable_sort(sorted.begin(),sorted.end(),[this](int a,int b){return m_sort=="title"?m_notes[a].title.localeAwareCompare(m_notes[b].title)<0:m_notes[a].order>m_notes[b].order;});
    for(int destination=0;destination<sorted.size();++destination) {
        int source=m_rows.indexOf(sorted[destination]);
        if(source!=destination) { beginMoveRows({},source,source,{},destination); m_rows.move(source,destination); endMoveRows(); }
    }
}
void NotesStore::touch(Note &n) { n.edited="just now"; n.order=QDateTime::currentMSecsSinceEpoch(); }
void NotesStore::scheduleSave() { m_saveStatus=m_autosave?"Saving…":"Unsaved changes"; emit saveStatusChanged(); if(m_autosave) m_saveTimer.start(); }
void NotesStore::createNote() {
    if(m_workspace=="Archive" || m_workspace=="Favorites" || m_workspace=="All Notes" || m_workspace=="Recent") setWorkspace("Personal");
    bool hadFilters=!m_query.isEmpty()||m_favoritesOnly;
    m_query.clear(); m_favoritesOnly=false; emit queryChanged(); emit filterChanged();
    if(hadFilters) rebuild(false);
    Note n; n.id=QUuid::createUuid().toString(QUuid::WithoutBraces); n.workspace=m_workspace; n.body=""; touch(n);
    m_notes.append(n);
    // A real insertion lets the QML view animate the new row without disturbing its siblings.
    if(m_sort!="title") { beginInsertRows({},0,0); m_rows.prepend(m_notes.size()-1); endInsertRows(); }
    else rebuild(false);
    m_selected=n.id; emit countsChanged(); emit selectedNoteChanged(); scheduleSave();
}
void NotesStore::renameNote(const QString &id,const QString &value) { auto n=find(id); if(!n||n->title==value)return; n->title=value; touch(*n); refreshOrdering(); notifyRow(id); emit selectedNoteChanged(); scheduleSave(); }
void NotesStore::renameSelected(const QString &value) { renameNote(m_selected,value); }
void NotesStore::updateBody(const QString &html) { auto n=selected(); if(!n||n->body==html)return; n->body=html; touch(*n); refreshOrdering(); notifyRow(n->id); emit selectedNoteChanged(); scheduleSave(); }
void NotesStore::toggleFavorite() { toggleFavoriteFor(m_selected); }
void NotesStore::toggleFavoriteFor(const QString &id) { auto n=find(id); if(!n)return; n->favorite=!n->favorite; if(m_workspace=="Favorites"||m_favoritesOnly)rebuild(); else notifyRow(id); emit selectedNoteChanged(); emit countsChanged(); scheduleSave(); }
void NotesStore::duplicateNote(const QString &id) { auto n=find(id); if(!n)return; Note copy=*n; copy.id=QUuid::createUuid().toString(QUuid::WithoutBraces); copy.title += " — copy"; touch(copy); m_notes.append(copy); m_selected=copy.id; rebuild(); scheduleSave(); }
void NotesStore::archiveNote(const QString &id) { auto n=find(id); if(!n)return; n->archived=true; touch(*n); rebuild(); scheduleSave(); }
void NotesStore::restoreNote(const QString &id) { auto n=find(id); if(!n)return; n->archived=false; touch(*n); rebuild(); scheduleSave(); }
void NotesStore::moveNote(const QString &id,const QString &workspace) { if(!QStringList{"Personal","Design","Research","Ideas"}.contains(workspace))return; auto n=find(id); if(!n)return; n->workspace=workspace; touch(*n); rebuild(); scheduleSave(); }
void NotesStore::copyNote() { auto n=selected(); if(!n)return; QTextDocument d; d.setHtml(n->body); QGuiApplication::clipboard()->setText("# "+(n->title.isEmpty()?"Untitled":n->title)+"\n\n"+d.toMarkdown()); }
bool NotesStore::exportNote(const QUrl &url) { auto n=selected(); if(!n)return false; QSaveFile f(url.toLocalFile()); if(!f.open(QIODevice::WriteOnly)){emit errorOccurred("Could not export this note.");return false;} QTextDocument d; d.setHtml(n->body); f.write(("# "+n->title+"\n\n"+d.toMarkdown()).toUtf8()); if(!f.commit()){emit errorOccurred("Could not finish exporting this note.");return false;} return true; }
bool NotesStore::load() {
    QFile f(m_path); if(!f.open(QIODevice::ReadOnly))return false;
    QJsonParseError error; auto doc=QJsonDocument::fromJson(f.readAll(),&error);
    if(error.error!=QJsonParseError::NoError || !doc.isArray()) { emit errorOccurred("Saved notes could not be read."); return false; }
    for(auto value:doc.array()) { auto o=value.toObject(); Note n; n.id=o["id"].toString(); if(n.id.isEmpty())continue; n.title=o["title"].toString(); n.body=o["body"].toString(); n.workspace=o["workspace"].toString(); n.edited=o["edited"].toString("earlier"); n.favorite=o["favorite"].toBool(); n.archived=o["archived"].toBool(); n.order=static_cast<qint64>(o["order"].toDouble()); for(auto t:o["tags"].toArray())n.tags.append(t.toString()); m_notes.append(n); }
    return true;
}
void NotesStore::save() {
    m_saveTimer.stop();
    if(!m_demo) {
        QDir().mkpath(QFileInfo(m_path).absolutePath());
        QJsonArray array; for(const auto &n:m_notes) { QJsonObject o{{"id",n.id},{"title",n.title},{"body",n.body},{"workspace",n.workspace},{"edited",n.edited},{"favorite",n.favorite},{"archived",n.archived},{"order",static_cast<double>(n.order)},{"tags",QJsonArray::fromStringList(n.tags)}}; array.append(o); }
        QSaveFile f(m_path);
        if(!f.open(QIODevice::WriteOnly) || f.write(QJsonDocument(array).toJson())<0 || !f.commit()) { m_saveStatus="Save failed"; emit saveStatusChanged(); emit errorOccurred("Could not save notes. Your current work is still open."); return; }
    }
    m_saveStatus="Saved locally"; emit saveStatusChanged();
}
void NotesStore::seed() {
    auto add=[this](QString id,QString title,QString workspace,QString body,QString edited,bool favorite,QStringList tags={}) {
        Note n; n.id=id; n.title=title; n.workspace=workspace; n.body=body; n.edited=edited; n.favorite=favorite; n.tags=tags; n.order=10000-m_notes.size(); m_notes.append(n);
    };
    add("visual-rhythm","Visual Rhythm","Design",R"(<html><body>
<h1 style="font-family:'Noto Serif'; font-size:32px; font-weight:500; margin-top:0; margin-bottom:10px;">Visual Rhythm</h1>
<p style="margin-top:0; margin-bottom:10px;">Good interfaces rarely feel evenly spaced.</p>
<p style="margin-top:0; margin-bottom:14px;">Important elements need room to breathe. Keep related controls closer together.</p>
<h2 style="font-size:19px; font-weight:600; margin-top:12px; margin-bottom:6px;">A few principles to keep close</h2>
<ul style="margin-top:0; margin-bottom:0; margin-left:10px;"><li style="margin-top:0; margin-bottom:5px;">Group by meaning, not by proximity alone.</li><li style="margin-top:0; margin-bottom:5px;">Give the most important idea room to breathe.</li><li style="margin-top:0; margin-bottom:5px;">Let repetition create a quiet sense of order.</li></ul>
<blockquote style="margin-top:16px; margin-bottom:16px; margin-left:20px;"><p style="margin-top:0; margin-bottom:5px; font-family:'Noto Serif'; font-size:18px; font-style:italic; color:#A5A29C;">“Whitespace is not an absence. It is an active part of the composition.”</p></blockquote>
<p style="margin-top:0; margin-bottom:14px;">Think in relationships, not fixed numbers. Try a <span style="font-family:'JetBrains Mono';font-size:14px;background-color:#24292E;color:#DFA56B;">spacing / 8</span> scale, then trust your eye.</p>
<p style="margin-top:0; margin-bottom:14px;"><span style="background-color:#443529;color:#F2D2AA;">The space between things is part of the design.</span></p>
<hr style="margin-top:0; margin-bottom:6px; color:#2D3339; background-color:#2D3339;" />
<h2 style="font-size:19px; font-weight:600; margin-top:18px; margin-bottom:8px;">Putting it into practice</h2>
<p style="margin-top:0; margin-bottom:8px;">Start with the content. Find its natural groups, then create pauses and connections.</p>
</body></html>)","12 min ago",true,{"design thinking","principles"});
    add("landing-page","Landing Page Ideas","Design",R"(<h1>Landing Page Ideas</h1><p>A good first impression is an invitation, not a pitch.</p><p>Lead with a clear promise. Follow with one believable example of the product in use.</p><h2>Three directions</h2><ul><li>An editorial hero with a product moment</li><li>A quiet canvas with a single strong statement</li><li>A story told through the people who use it</li></ul><blockquote><p>Make the next step obvious. Make the choice feel natural.</p></blockquote><p>Keep the navigation light and put the product where it can speak for itself.</p>)","38 min ago",false,{"website","exploration"});
    add("typography","Typography Notes","Design",R"(<h1>Typography Notes</h1><p>Type sets the voice before the words are read.</p><p>Pair a practical sans serif for the interface with a measured serif for longer reading. Let the difference be subtle.</p><h2>A considered type scale</h2><ul><li>12–13 px for quiet labels</li><li>14 px for navigation and controls</li><li>16–18 px for comfortable reading</li><li>28–32 px for an editorial title</li></ul><blockquote><p>Good typography turns reading into a place you want to stay.</p></blockquote><p>Watch the measure: around 65 to 80 characters per line. More space between lines can be more valuable than more pixels in the font.</p>)","1 hour ago",true,{"typography","reference"});
    add("motion","Motion References","Design",R"(<h1>Motion References</h1><p>Motion should make the interface easier to understand.</p><h2>Timing notes</h2><ul><li>Hover feedback: 120 ms</li><li>Panel transitions: 200 ms</li><li>Modal entrance: 180 ms</li></ul><p>Use ease-out curves for entrances. Avoid movement that competes with the content.</p><blockquote><p>The best animation is the one you notice only when it is missing.</p></blockquote>)","Yesterday",false,{"motion"});
    add("component-audit","Component Audit","Design",R"(<h1>Component Audit</h1><p>A small inventory of the patterns that deserve a second look.</p><ul><li>Unify button heights and icon weights.</li><li>Replace nested cards with simple spacing.</li><li>Keep focus indicators visible in both themes.</li><li>Check empty states and disabled controls.</li></ul><h2>Next review</h2><p>Start with the densest screens. Look for places where the hierarchy asks the reader to work too hard.</p>)","Yesterday",false,{"systems","review"});
    add("portfolio","Portfolio Structure","Design",R"(<h1>Portfolio Structure</h1><p>A collection of work should tell a story about judgment.</p><h2>Case study outline</h2><ol><li>The question we started with</li><li>The choices that shaped the solution</li><li>The details that made it work</li><li>What we learned along the way</li></ol><p>Show fewer projects, with more care. Give each project a strong opening and a clear outcome.</p>)","2 days ago",false,{"portfolio"});
    add("color","Color Studies","Design",R"(<h1>Color Studies</h1><p>Warm neutrals give the accent room to do its job.</p><p>Charcoal, parchment, and copper. A palette that feels collected rather than decorated.</p><h2>Rules of restraint</h2><ul><li>Use one accent with a purpose.</li><li>Build depth with surfaces, not shadows.</li><li>Test every secondary label for contrast.</li></ul><p>Light themes should have their own warmth and hierarchy.</p>)","3 days ago",true,{"color","experiments"});
    add("small-rituals","Small Rituals","Personal","<h1>Small Rituals</h1><p>Take a walk before opening the inbox. Write one sentence before reading the news.</p><p>A few small choices can change the shape of a day.</p>","Today",false,{"daily"});
    add("reading-list","Reading List","Personal","<h1>Reading List</h1><ul><li>The Creative Act — Rick Rubin</li><li>A Pattern Language — Christopher Alexander</li><li>The Design of Everyday Things — Don Norman</li></ul><p>Read slowly. Keep the ideas that change how you see.</p>","Yesterday",true);
    add("weekend","Weekend Plans","Personal","<h1>Weekend Plans</h1><p>Visit the bookshop, find a new walking route, and make time for a long lunch.</p>","2 days ago",false);
    add("journal","October Journal","Personal","<h1>October Journal</h1><p>A fresh page for observations, questions, and small things worth remembering.</p>","3 days ago",false);
    add("attention","Designing for Attention","Research","<h1>Designing for Attention</h1><p>What makes a digital space feel calm?</p><p>Research questions: interruption cost, visual complexity, and the role of predictable interaction.</p><h2>Working hypothesis</h2><p>People stay focused when the interface makes the next action clear without making every action equally prominent.</p>","Today",true,{"cognition"});
    add("materials","Digital Materials","Research","<h1>Digital Materials</h1><p>The texture of a digital product comes from its rhythm, responses, and restraint.</p><blockquote><p>A surface does not need to imitate paper to feel tactile.</p></blockquote>","Yesterday",false);
    add("interviews","Interview Notes","Research","<h1>Interview Notes</h1><p>People return to notes that help them make a connection.</p><ul><li>Capture quickly.</li><li>Find it later.</li><li>Make something new from what you kept.</li></ul>","3 days ago",false);
    add("quiet-tools","Quiet Tools","Ideas","<h1>Quiet Tools</h1><p>What if our tools made fewer demands on our attention?</p><p>Build for the moment after the interface disappears and the work begins.</p>","Today",false);
    add("garden","A Personal Knowledge Garden","Ideas","<h1>A Personal Knowledge Garden</h1><p>Notes as seeds. Connections as paths. A workspace that grows at your pace.</p>","Yesterday",true);
    m_selected="visual-rhythm";
}
