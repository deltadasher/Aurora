#include "DocumentHandler.h"
#include <QTextBlock>
#include <QTextDocument>
#include <QTextFragment>
#include <QTextList>
#include <QUrl>

void DocumentHandler::setDocument(QQuickTextDocument *value) {
    if(m_document==value)return;
    if(m_document && m_document->textDocument())disconnect(m_document->textDocument(),nullptr,this,nullptr);
    m_document=value;
    if(value)connect(value->textDocument(),&QTextDocument::contentsChanged,this,&DocumentHandler::formattingChanged);
    emit documentChanged(); emit formattingChanged();
}
QTextCursor DocumentHandler::cursor(bool selectWord) const {
    if(!m_document || !m_document->textDocument())return {};
    QTextCursor c(m_document->textDocument());
    int max=m_document->textDocument()->characterCount()-1;
    c.setPosition(qBound(0,m_start!=m_end?m_start:m_position,max));
    if(m_start!=m_end)c.setPosition(qBound(0,m_end,max),QTextCursor::KeepAnchor);
    else if(selectWord)c.select(QTextCursor::WordUnderCursor);
    return c;
}
bool DocumentHandler::bold() const { return cursor().charFormat().fontWeight()>=QFont::DemiBold; }
bool DocumentHandler::italic() const { return cursor().charFormat().fontItalic(); }
int DocumentHandler::heading() const { return cursor().blockFormat().headingLevel(); }
bool DocumentHandler::highlighted() const { auto c=cursor(); return !c.isNull() && c.charFormat().background().style()!=Qt::NoBrush && !c.charFormat().fontFamilies().toStringList().contains("JetBrains Mono"); }
void DocumentHandler::toggleBold() { auto c=cursor(true); if(c.isNull())return; QTextCharFormat f; f.setFontWeight(bold()?QFont::Normal:QFont::Bold); c.mergeCharFormat(f); emit formattingChanged(); }
void DocumentHandler::toggleItalic() { auto c=cursor(true); if(c.isNull())return; QTextCharFormat f; f.setFontItalic(!italic()); c.mergeCharFormat(f); emit formattingChanged(); }
void DocumentHandler::setHeading(int level) {
    auto c=cursor(); if(c.isNull())return;
    level=heading()==level?0:level;
    auto d=m_document->textDocument();
    const int first=c.selectionStart();
    const int last=c.hasSelection()?qMax(first,c.selectionEnd()-1):first;
    auto firstBlock=d->findBlock(first),lastBlock=d->findBlock(last);
    c.setPosition(firstBlock.position());
    c.setPosition(lastBlock.position()+lastBlock.length()-1,QTextCursor::KeepAnchor);
    c.beginEditBlock(); QTextBlockFormat b; b.setHeadingLevel(level); b.setTopMargin(level?24:0); b.setBottomMargin(level?14:18); c.mergeBlockFormat(b);
    QTextCharFormat f; f.setProperty(QTextFormat::FontPixelSize,level==1?m_fontSize*2:level==2?qRound(m_fontSize*1.25):level==3?qRound(m_fontSize*1.125):m_fontSize); f.setFontWeight(level?QFont::DemiBold:QFont::Normal); f.setFontFamilies({level>1?"Noto Sans":"Noto Serif"}); c.mergeCharFormat(f); c.endEditBlock(); emit formattingChanged();
}
void DocumentHandler::toggleQuote() {
    auto c=cursor(); if(c.isNull())return;
    const bool active=!c.currentList()&&(c.blockFormat().indent()>0||c.blockFormat().leftMargin()>=20);
    auto d=m_document->textDocument();
    const int first=c.selectionStart(),last=c.hasSelection()?qMax(first,c.selectionEnd()-1):first;
    auto firstBlock=d->findBlock(first),lastBlock=d->findBlock(last);
    c.setPosition(firstBlock.position());c.setPosition(lastBlock.position()+lastBlock.length()-1,QTextCursor::KeepAnchor);
    c.beginEditBlock();
    QTextBlockFormat f; f.setIndent(active?0:1); f.setLeftMargin(active?0:12); f.setBottomMargin(20); c.mergeBlockFormat(f);
    QTextCharFormat cf; cf.setFontItalic(!active); cf.setForeground(QColor(active?(m_dark?"#F2F0EB":"#1E2023"):(m_dark?"#A5A29C":"#6F6D68"))); c.mergeCharFormat(cf);
    c.endEditBlock();emit formattingChanged();
}
void DocumentHandler::list(int style) {
    auto c=cursor(); if(c.isNull())return; c.beginEditBlock();
    if(c.currentList() && c.currentList()->format().style()==style) {
        auto d=m_document->textDocument();
        const int first=c.selectionStart(),last=c.hasSelection()?qMax(first,c.selectionEnd()-1):first;
        auto lastBlock=d->findBlock(last);
        for(auto block=d->findBlock(first);block.isValid();block=block.next()) {
            auto existing=block.textList();
            if(existing && existing->format().style()==style)existing->remove(block);
            QTextCursor blockCursor(block); QTextBlockFormat f=block.blockFormat(); f.setIndent(0); blockCursor.setBlockFormat(f);
            if(block==lastBlock)break;
        }
    } else { QTextListFormat f; f.setStyle(static_cast<QTextListFormat::Style>(style)); f.setIndent(1); c.createList(f); }
    c.endEditBlock(); emit formattingChanged();
}
void DocumentHandler::toggleBullets() { list(QTextListFormat::ListDisc); }
void DocumentHandler::toggleNumbers() { list(QTextListFormat::ListDecimal); }
void DocumentHandler::toggleCode() { auto c=cursor(true); if(c.isNull())return; bool active=c.charFormat().fontFamilies().toStringList().contains("JetBrains Mono"); QTextCharFormat f; f.setFontFamilies({active?"Noto Serif":"JetBrains Mono"}); f.setProperty(QTextFormat::FontPixelSize,active?m_fontSize:m_fontSize-2); f.setForeground(QColor(active?(m_dark?"#F2F0EB":"#1E2023"):m_accent)); if(active)f.setBackground(Qt::NoBrush); else f.setBackground(QColor(m_dark?"#24292E":"#E5E1D9")); c.mergeCharFormat(f); emit formattingChanged(); }
void DocumentHandler::toggleHighlight() { auto c=cursor(true); if(c.isNull())return; QTextCharFormat f; if(highlighted()) {f.setBackground(Qt::NoBrush);f.setForeground(QColor(m_dark?"#F2F0EB":"#1E2023"));}else {f.setBackground(QColor(m_dark?"#443529":"#F0D7B9"));f.setForeground(QColor(m_dark?"#F2D2AA":"#704723"));} c.mergeCharFormat(f); emit formattingChanged(); }
void DocumentHandler::setLink(const QString &url) { auto c=cursor(true); if(c.isNull())return; auto parsed=QUrl::fromUserInput(url.trimmed()); if(parsed.scheme()!="https" && parsed.scheme()!="http" && parsed.scheme()!="mailto")return; QTextCharFormat f;f.setAnchor(true);f.setAnchorHref(parsed.toString());f.setFontUnderline(true);f.setForeground(QColor(m_accent));c.mergeCharFormat(f);emit formattingChanged(); }
void DocumentHandler::setLineHeight(qreal value) {
    if(!m_document)return; auto d=m_document->textDocument(); QTextCursor c(d); c.beginEditBlock();
    for(auto block=d->begin();block.isValid();block=block.next()) { c.setPosition(block.position()); auto f=block.blockFormat();f.setLineHeight(value*100,QTextBlockFormat::ProportionalHeight); c.setBlockFormat(f); }
    c.endEditBlock();
}
void DocumentHandler::restyle(bool dark,const QString &accent,int fontSize,qreal lineHeight) {
    if(!m_document)return;
    m_dark=dark;m_accent=accent;m_fontSize=fontSize;
    auto d=m_document->textDocument(); const bool modified=d->isModified();
    // Keep the user's undo history intact. Presentation updates form one edit
    // block and are excluded from autosave by the editor while restyle runs.
    QColor text(dark?"#F2F0EB":"#1E2023"),secondary(dark?"#A5A29C":"#6F6D68");
    QFont font("Noto Serif");font.setPixelSize(fontSize);d->setDefaultFont(font);
    QTextCursor c(d); c.beginEditBlock();
    struct Span {int start,length;QTextCharFormat format;};
    QList<Span> spans;
    for(auto block=d->begin();block.isValid();block=block.next()) {
        c.setPosition(block.position()); auto bf=block.blockFormat();bf.setLineHeight(lineHeight*100,QTextBlockFormat::ProportionalHeight);
        if(bf.hasProperty(QTextFormat::BlockTrailingHorizontalRulerWidth)) {
            const QColor rulerColor(dark?"#2D3339":"#D9D5CE");
            QTextCharFormat ruler; ruler.setForeground(rulerColor); ruler.setBackground(rulerColor); ruler.setProperty(QTextFormat::FontPixelSize,1);
            c.setBlockCharFormat(ruler);
            bf.setForeground(QColor(dark?"#2D3339":"#D9D5CE"));
            bf.setBackground(rulerColor);
            bf.setLineHeight(1,QTextBlockFormat::FixedHeight);
            bf.setTopMargin(6); bf.setBottomMargin(8);
        }
        int heading=bf.headingLevel(); bool quote=!block.textList()&&(bf.indent()>0||bf.leftMargin()>=20);
        if(!heading && bf.bottomMargin()<5)bf.setBottomMargin(block.textList()?7:18);
        c.setBlockFormat(bf);
        for(auto it=block.begin();!it.atEnd();++it) {
            auto frag=it.fragment();if(!frag.isValid())continue;auto f=frag.charFormat();
            bool code=f.fontFamilies().toStringList().contains("JetBrains Mono");bool highlighted=f.background().style()!=Qt::NoBrush&&!code;
            if(code) {f.setForeground(QColor(accent));f.setBackground(QColor(dark?"#24292E":"#E5E1D9"));f.setProperty(QTextFormat::FontPixelSize,fontSize-2);}
            else if(highlighted){f.setBackground(QColor(dark?"#443529":"#F0D7B9"));f.setForeground(QColor(dark?"#F2D2AA":"#704723"));f.setProperty(QTextFormat::FontPixelSize,fontSize);}
            else {f.setForeground(f.isAnchor()?QColor(accent):quote?secondary:text);f.setProperty(QTextFormat::FontPixelSize,heading==1?fontSize*2:heading==2?qRound(fontSize*1.25):heading==3?qRound(fontSize*1.125):fontSize);}
            if(heading>1)f.setFontFamilies({"Noto Sans"});
            spans.append({frag.position(),frag.length(),f});
        }
    }
    for(const auto &s:spans){c.setPosition(s.start);c.setPosition(s.start+s.length,QTextCursor::KeepAnchor);c.setCharFormat(s.format);}
    c.endEditBlock(); d->setModified(modified); emit formattingChanged();
}
