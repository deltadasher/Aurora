import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Aurora 1.0

Item {
    id: root
    property bool sidebarHidden: false
    property bool noteListHidden: false
    property bool loading: false
    property string loadedId: ""
    property bool focusMode: false
    property bool restoreSidebar: false
    property bool restoreNoteList: false
    signal archiveRequested(string id)
    signal shareRequested()
    signal sidebarRequested()
    signal noteListRequested()

    function focusTitle() {
        titleField.forceActiveFocus()
        titleField.selectAll()
    }
    function focusBody() { body.forceActiveFocus() }
    function loadSelected() {
        if (loadedId === String(notes.selectedId)) {
            if (!titleField.activeFocus && titleField.text !== notes.title)
                titleField.text = notes.title
            return
        }
        loading = true
        loadedId = String(notes.selectedId)
        titleField.text = notes.title
        body.deselect()
        body.cursorPosition = 0
        body.text = notes.body
        body.cursorPosition = 0
        editorScroll.contentY = 0
        loading = false
        Qt.callLater(restyleDocument)
    }
    function restyleDocument() {
        if (notes.hasSelection) {
            var wasLoading = loading
            loading = true
            formatter.restyle(Theme.dark, Theme.accent, Theme.editorFontSize, Theme.lineHeight)
            loading = wasLoading
        }
    }
    function openLink() {
        linkField.text = ""
        linkPopup.open()
        linkField.forceActiveFocus()
    }
    function toggleFocus() {
        if (!focusMode) {
            restoreSidebar = !sidebarHidden
            restoreNoteList = !noteListHidden
            if (restoreSidebar) sidebarRequested()
            if (restoreNoteList) noteListRequested()
        } else {
            if (restoreSidebar && sidebarHidden) sidebarRequested()
            if (restoreNoteList && noteListHidden) noteListRequested()
        }
        focusMode = !focusMode
    }

    Component.onCompleted: loadSelected()
    Connections {
        target: notes
        ignoreUnknownSignals: true
        function onSelectedNoteChanged() { root.loadSelected() }
        function onSelectedIdChanged() { root.loadSelected() }
    }
    Connections {
        target: Theme
        function onDarkChanged() { root.restyleDocument() }
        function onAccentChanged() { styleUpdate.restart() }
        function onEditorFontSizeChanged() { styleUpdate.restart() }
        function onLineHeightChanged() { styleUpdate.restart() }
    }
    Timer { id: styleUpdate; interval: Theme.motion + 20; onTriggered: root.restyleDocument() }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        Behavior on color { ColorAnimation { duration: Theme.motion } }
    }

    Item {
        id: editorContent
        anchors.fill: parent
        visible: notes.hasSelection

        Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.sidebarHidden || root.noteListHidden ? 134 : 108

            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: 22
                anchors.top: parent.top
                anchors.topMargin: 17
                spacing: 4
                visible: root.sidebarHidden || root.noteListHidden
                AuroraButton {
                    visible: root.sidebarHidden
                    iconName: "sidebar"
                    tooltip: "Show navigation"
                    onClicked: root.sidebarRequested()
                }
                AuroraButton {
                    visible: root.noteListHidden
                    iconName: "list"
                    tooltip: "Show note list"
                    onClicked: root.noteListRequested()
                }
            }

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 30
                anchors.rightMargin: 22
                anchors.top: parent.top
                anchors.topMargin: root.sidebarHidden || root.noteListHidden ? 56 : 25
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    TextField {
                        id: titleField
                        objectName: "editorTitle"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 33
                        padding: 0
                        topPadding: 0
                        bottomPadding: 1
                        placeholderText: "Untitled"
                        placeholderTextColor: Theme.muted
                        color: Theme.text
                        selectionColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.30)
                        selectedTextColor: Theme.text
                        font.family: Theme.uiFont
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        maximumLength: 180
                        selectByMouse: true
                        Accessible.name: "Note title"
                        onTextEdited: notes.title = text
                        onActiveFocusChanged: {
                            if (!activeFocus && root.loadedId === String(notes.selectedId) && text !== notes.title)
                                text = notes.title
                        }
                        onAccepted: body.forceActiveFocus()
                        background: Item {
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: Theme.accent
                                opacity: titleField.activeFocus ? 0.65 : 0
                                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: notes.editedLabel + "  ·  " + notes.selectedWorkspace
                        font.family: Theme.uiFont
                        font.pixelSize: 11
                        color: Theme.muted
                        elide: Text.ElideRight
                    }
                }

                AuroraButton {
                    objectName: "favoriteButton"
                    iconName: "star"
                    tooltip: notes.favorite ? "Remove from favorites" : "Add to favorites"
                    selected: notes.favorite
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 2
                    onClicked: notes.toggleFavorite()
                }
                AuroraButton {
                    objectName: "shareButton"
                    iconName: "share"
                    text: root.width > 520 ? "Share" : ""
                    tooltip: "Share note"
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 2
                    onClicked: root.shareRequested()
                }
                AuroraButton {
                    id: moreButton
                    objectName: "editorMoreButton"
                    iconName: "more"
                    tooltip: "More actions"
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 2
                    onClicked: moreMenu.popup(width - moreMenu.width, height + 6)
                    AuroraMenu {
                        id: moreMenu
                        Action { text: "Copy note"; onTriggered: notes.copyNote() }
                        MenuSeparator { contentItem: Rectangle { implicitHeight: 1; color: Theme.border } }
                        Action {
                            text: "Archive note"
                            onTriggered: root.archiveRequested(notes.selectedId)
                        }
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Theme.border
                opacity: 0.6
            }
        }

        EditorToolbar {
            id: toolbar
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            handler: formatter
            onLinkRequested: root.openLink()
        }

        Flickable {
            id: editorScroll
            objectName: "editorScroll"
            anchors.top: toolbar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: footer.top
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: paper.height + 76
            flickableDirection: Flickable.VerticalFlick
            ScrollBar.vertical: ThinScrollBar { }

            Item {
                id: paper
                width: Math.min(780, Math.max(260, editorScroll.width - 76))
                x: (editorScroll.width - width) / 2
                y: 32
                height: body.height

                Rectangle {
                    visible: Theme.showGuide
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: -18
                    width: 1
                    color: Theme.border
                    opacity: 0.6
                }

                TextArea {
                    id: body
                    objectName: "editorBody"
                    width: parent.width
                    height: Math.max(editorScroll.height - 84, contentHeight + 20)
                    padding: 0
                    topPadding: 0
                    bottomPadding: 20
                    textFormat: TextEdit.RichText
                    wrapMode: TextEdit.Wrap
                    font.family: Theme.serifFont
                    font.pixelSize: Theme.editorFontSize
                    color: Theme.text
                    selectionColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.30)
                    selectedTextColor: Theme.text
                    placeholderText: "Start writing…"
                    placeholderTextColor: Theme.muted
                    selectByMouse: true
                    persistentSelection: true
                    Accessible.name: "Note body"
                    background: null
                    onTextChanged: {
                        if (!root.loading && root.loadedId === String(notes.selectedId))
                            notes.updateBody(text)
                    }
                    onCursorRectangleChanged: {
                        if (!activeFocus) return
                        var top = paper.y + cursorRectangle.y
                        if (top < editorScroll.contentY + 18)
                            editorScroll.contentY = Math.max(0, top - 18)
                        else if (top + cursorRectangle.height > editorScroll.contentY + editorScroll.height - 18)
                            editorScroll.contentY = Math.min(Math.max(0, editorScroll.contentHeight - editorScroll.height), top + cursorRectangle.height - editorScroll.height + 18)
                    }
                    Keys.onPressed: function(event) {
                        if (event.modifiers & Qt.ControlModifier || event.modifiers & Qt.MetaModifier) {
                            if (event.key === Qt.Key_B) { formatter.toggleBold(); event.accepted = true }
                            else if (event.key === Qt.Key_I) { formatter.toggleItalic(); event.accepted = true }
                            else if (event.key === Qt.Key_L) { root.openLink(); event.accepted = true }
                        }
                    }
                }
            }
        }

        DocumentHandler {
            id: formatter
            document: body.textDocument
            cursorPosition: body.cursorPosition
            selectionStart: body.selectionStart
            selectionEnd: body.selectionEnd
        }

        Rectangle {
            id: selectionToolbar
            objectName: "selectionToolbar"
            property bool shown: body.selectionStart !== body.selectionEnd && !linkPopup.opened
            property rect selectionRect: body.positionToRectangle(Math.max(0, Math.min(body.selectionStart, body.selectionEnd)))
            width: selectionRow.implicitWidth + 14
            height: 40
            z: 8
            radius: 7
            color: Theme.surface
            border.color: Theme.border
            x: Math.max(18, Math.min(root.width - width - 18, paper.x + selectionRect.x - width / 2))
            property real selectionY: toolbar.y + toolbar.height + paper.y + selectionRect.y - editorScroll.contentY - 49
            y: Math.max(toolbar.y + toolbar.height + 9, Math.min(footer.y - height - 12, selectionY)) + (shown ? 0 : 5)
            opacity: shown ? 1 : 0
            scale: shown ? 1 : 0.98
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
            RowLayout {
                id: selectionRow
                anchors.centerIn: parent
                spacing: 2
                AuroraButton {
                    objectName: "selectionBoldButton"
                    iconName: "bold"
                    tooltip: "Bold"
                    selected: formatter.bold
                    focusPolicy: Qt.NoFocus
                    onClicked: formatter.toggleBold()
                }
                AuroraButton {
                    objectName: "selectionItalicButton"
                    iconName: "italic"
                    tooltip: "Italic"
                    selected: formatter.italic
                    focusPolicy: Qt.NoFocus
                    onClicked: formatter.toggleItalic()
                }
                AuroraButton {
                    objectName: "highlightButton"
                    iconName: "highlight"
                    tooltip: "Highlight"
                    selected: formatter.highlighted
                    focusPolicy: Qt.NoFocus
                    onClicked: formatter.toggleHighlight()
                }
                AuroraButton {
                    objectName: "selectionLinkButton"
                    iconName: "link"
                    tooltip: "Add a link"
                    focusPolicy: Qt.NoFocus
                    onClicked: root.openLink()
                }
            }
        }

        Item {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 39
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: Theme.border
                opacity: 0.45
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 28
                anchors.rightMargin: 20
                spacing: 10
                Text {
                    text: notes.wordCount + " words"
                    font.family: Theme.uiFont
                    font.pixelSize: 10
                    color: Theme.muted
                }
                Rectangle { Layout.preferredWidth: 2; Layout.preferredHeight: 2; radius: 1; color: Theme.muted }
                Text {
                    text: notes.saveStatus
                    font.family: Theme.uiFont
                    font.pixelSize: 10
                    color: Theme.muted
                }
                Item { Layout.fillWidth: true }
                AuroraButton {
                    text: root.focusMode ? "Exit focus" : "Focus"
                    iconName: "focus"
                    tooltip: "Focus mode"
                    selected: root.focusMode
                    onClicked: root.toggleFocus()
                }
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(310, root.width - 48)
        spacing: 13
        visible: !notes.hasSelection
        Icon { name: "note"; size: 34; color: Theme.muted; Layout.alignment: Qt.AlignHCenter }
        Text {
            text: "A little room to think."
            font.family: Theme.serifFont
            font.pixelSize: 23
            color: Theme.text
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            text: "Select a note, or start with a fresh page."
            font.family: Theme.uiFont
            font.pixelSize: 12
            color: Theme.secondary
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        AuroraButton {
            text: "New note"
            iconName: "plus"
            quiet: false
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            onClicked: { notes.createNote(); Qt.callLater(root.focusTitle) }
        }
    }

    Popup {
        id: linkPopup
        objectName: "linkPopup"
        parent: Overlay.overlay
        x: Math.max(16, (parent.width - width) / 2)
        y: Math.max(30, (parent.height - height) / 2 - 35)
        width: Math.min(380, parent.width - 40)
        padding: 22
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onClosed: body.forceActiveFocus()
        background: Rectangle {
            color: Theme.surface
            border.color: Theme.border
            radius: 10
        }
        Overlay.modal: Rectangle { color: "#59000000" }
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.motion }
                NumberAnimation { property: "scale"; from: 0.98; to: 1; duration: Theme.motion; easing.type: Easing.OutCubic }
            }
        }
        contentItem: ColumnLayout {
            spacing: 15
            Text {
                text: "Add a link"
                font.family: Theme.uiFont
                font.pixelSize: 17
                font.weight: Font.DemiBold
                color: Theme.text
            }
            TextField {
                id: linkField
                objectName: "linkUrlField"
                Layout.fillWidth: true
                implicitHeight: 39
                placeholderText: "https://example.com"
                placeholderTextColor: Theme.muted
                color: Theme.text
                selectionColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.30)
                font.family: Theme.uiFont
                font.pixelSize: 12
                padding: 10
                selectByMouse: true
                background: Rectangle {
                    radius: 6
                    color: Theme.bg
                    border.color: linkField.activeFocus ? Theme.accent : Theme.border
                }
                onAccepted: if (text.trim().length) addLinkButton.clicked()
            }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                AuroraButton { text: "Cancel"; onClicked: linkPopup.close() }
                AuroraButton {
                    id: addLinkButton
                    text: "Add link"
                    quiet: false
                    enabled: linkField.text.trim().length > 0
                    onClicked: {
                        var url = linkField.text.trim()
                        if (!/^[a-z][a-z0-9+.-]*:/i.test(url)) url = "https://" + url
                        formatter.setLink(url)
                        linkPopup.close()
                        body.forceActiveFocus()
                    }
                }
            }
        }
    }
}
