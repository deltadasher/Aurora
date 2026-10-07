#pragma once
#include <QObject>
#include <QPointer>
#include <QQuickTextDocument>
#include <QTextCursor>

class DocumentHandler : public QObject {
    Q_OBJECT
    Q_PROPERTY(QQuickTextDocument* document READ document WRITE setDocument NOTIFY documentChanged)
    Q_PROPERTY(int cursorPosition READ cursorPosition WRITE setCursorPosition NOTIFY formattingChanged)
    Q_PROPERTY(int selectionStart READ selectionStart WRITE setSelectionStart NOTIFY formattingChanged)
    Q_PROPERTY(int selectionEnd READ selectionEnd WRITE setSelectionEnd NOTIFY formattingChanged)
    Q_PROPERTY(bool bold READ bold NOTIFY formattingChanged)
    Q_PROPERTY(bool italic READ italic NOTIFY formattingChanged)
    Q_PROPERTY(int heading READ heading NOTIFY formattingChanged)
    Q_PROPERTY(bool highlighted READ highlighted NOTIFY formattingChanged)
public:
    explicit DocumentHandler(QObject *parent=nullptr) : QObject(parent) {}
    QQuickTextDocument *document() const { return m_document; }
    void setDocument(QQuickTextDocument *);
    int cursorPosition() const { return m_position; }
    int selectionStart() const { return m_start; }
    int selectionEnd() const { return m_end; }
    void setCursorPosition(int value) { if(m_position==value)return; m_position=value; emit formattingChanged(); }
    void setSelectionStart(int value) { if(m_start==value)return; m_start=value; emit formattingChanged(); }
    void setSelectionEnd(int value) { if(m_end==value)return; m_end=value; emit formattingChanged(); }
    bool bold() const;
    bool italic() const;
    int heading() const;
    bool highlighted() const;
    Q_INVOKABLE void toggleBold();
    Q_INVOKABLE void toggleItalic();
    Q_INVOKABLE void setHeading(int level);
    Q_INVOKABLE void toggleQuote();
    Q_INVOKABLE void toggleBullets();
    Q_INVOKABLE void toggleNumbers();
    Q_INVOKABLE void toggleCode();
    Q_INVOKABLE void toggleHighlight();
    Q_INVOKABLE void setLink(const QString &);
    Q_INVOKABLE void setLineHeight(qreal);
    Q_INVOKABLE void restyle(bool dark,const QString &accent,int fontSize,qreal lineHeight);
signals:
    void documentChanged();
    void formattingChanged();
private:
    QTextCursor cursor(bool selectWord=false) const;
    void list(int style);
    QPointer<QQuickTextDocument> m_document;
    int m_position=0,m_start=0,m_end=0,m_fontSize=16;
    bool m_dark=true;
    QString m_accent="#DFA56B";
};
