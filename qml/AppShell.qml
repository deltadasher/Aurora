import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: window
    objectName: "appWindow"
    width: 1440; height: 900
    minimumWidth: 700; minimumHeight: 600
    visible: true
    title: "Aurora Notes"
    color: Theme.bg
    flags: Qt.Window | Qt.FramelessWindowHint
    font.family: Theme.uiFont
    property int sidebarMode: 0 // 0 automatic, 1 expanded, 2 hidden
    property int listMode: 0
    property real noteListWidth: 300
    property string pendingArchiveId: ""
    readonly property bool sidebarVisible: sidebarMode !== 2
    readonly property bool sidebarCollapsed: width < 1050
    readonly property bool listVisible: width >= 820 && listMode !== 2
    onWidthChanged: { if(sidebarDrawer) sidebarDrawer.close(); if(noteDrawer) noteDrawer.close() }
    function toggleSidebar() {
        if(width < 1050) { sidebarMode=0; sidebarDrawer.open() }
        else sidebarMode = sidebarVisible ? 2 : 0
    }
    function toggleNoteList() {
        if(width < 820) noteDrawer.open()
        else listMode = listVisible ? 2 : 1
    }
    function newNote() { notes.createNote(); Qt.callLater(editor.focusTitle) }
    function requestArchive(id) {
        if (!id) return
        if (Theme.confirmArchive) { pendingArchiveId = id; archiveDialog.open() }
        else { notes.archiveNote(id); toast.show("Note archived") }
    }
    function executeCommand(command) {
        switch(command) {
        case "new": newNote(); break
        case "search": focusSearch(); break
        case "sidebar": toggleSidebar(); break
        case "list": toggleNoteList(); break
        case "theme": Theme.themeMode = Theme.dark ? "Light" : "Dark"; break
        case "light": Theme.themeMode = "Light"; break
        case "dark": Theme.themeMode = "Dark"; break
        case "settings": settingsDialog.open(); break
        case "archive": requestArchive(notes.selectedId); break
        }
    }
    function focusSearch() {
        if(width < 820) { noteDrawer.open(); Qt.callLater(drawerNoteList.focusSearch) }
        else { listMode=1; Qt.callLater(noteList.focusSearch) }
    }
    Component.onCompleted: { notes.autosave = Theme.autosave; notes.rememberWorkspace = Theme.openLastWorkspace }
    onClosing: if (Theme.autosave) notes.save()
    Connections {
        target: Theme
        function onAutosaveChanged() { notes.autosave = Theme.autosave }
        function onOpenLastWorkspaceChanged() { notes.rememberWorkspace = Theme.openLastWorkspace }
    }
    Connections { target: notes; function onErrorOccurred(message) { toast.show(message) } }
    Shortcut { sequences: ["Ctrl+K", "Meta+K"]; onActivated: commandPalette.open() }
    Shortcut { sequences: ["Ctrl+N", "Meta+N"]; onActivated: window.newNote() }
    Shortcut { sequences: ["Ctrl+F", "Meta+F"]; onActivated: window.focusSearch() }
    Shortcut { sequences: ["Ctrl+S", "Meta+S"]; onActivated: { notes.save(); toast.show("Notes saved") } }
    Shortcut { sequences: ["Ctrl+Shift+\\", "Meta+Shift+\\"]; onActivated: window.toggleSidebar() }
    Shortcut { sequences: ["Ctrl+,", "Meta+,"]; onActivated: settingsDialog.open() }

    Rectangle {
        id: titleBar
        anchors.top: parent.top
        width: parent.width; height: 40
        color: Theme.sidebar
        MouseArea {
            anchors.fill: parent
            onPressed: window.startSystemMove()
            onDoubleClicked: window.visibility === Window.Maximized ? window.showNormal() : window.showMaximized()
        }
        Row {
            x: 15; anchors.verticalCenter: parent.verticalCenter; spacing: 7
            Icon { name: "aurora"; size: 13; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Aurora Notes"; color: Theme.secondary; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            anchors.centerIn: parent; spacing: 6
            Text { text: notes.workspace; color: Theme.secondary; font.pixelSize: 10 }
            Text { text: "/"; color: Theme.muted; font.pixelSize: 10 }
            Text { text: notes.title || "Untitled"; color: Theme.muted; font.pixelSize: 10; width: Math.min(180,implicitWidth); elide: Text.ElideRight }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter; spacing: 2
            AuroraButton { objectName: "toggleSidebarButton"; iconName: "sidebar"; tooltip: "Toggle navigation"; width: 30; height: 26; onClicked: window.toggleSidebar() }
            AuroraButton { objectName: "toggleNoteListButton"; iconName: "list"; tooltip: "Toggle note list"; width: 30; height: 26; onClicked: window.toggleNoteList() }
            Rectangle { width: 1; height: 13; color: Theme.border; anchors.verticalCenter: parent.verticalCenter }
            AuroraButton { iconName: "minimize"; tooltip: "Minimize"; width: 31; height: 26; onClicked: window.showMinimized() }
            AuroraButton { iconName: window.visibility===Window.Maximized ? "restore" : "maximize"; tooltip: "Maximize or restore"; width: 31; height: 26; onClicked: window.visibility===Window.Maximized ? window.showNormal() : window.showMaximized() }
            AuroraButton { iconName: "close"; tooltip: "Close Aurora"; width: 31; height: 26; onClicked: window.close() }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.65 }
    }

    Item {
        id: columns
        anchors.top: titleBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        Item {
            id: navigationPane
            width: window.sidebarVisible ? (window.sidebarCollapsed ? 64 : 216) : 0
            height: parent.height
            clip: true
            Behavior on width { NumberAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
            Sidebar {
                id: sidebar
                width: navigationPane.width; height: parent.height
                collapsed: window.sidebarCollapsed
                visible: navigationPane.width > 48
                onNewNoteRequested: window.newNote()
                onSettingsRequested: settingsDialog.open()
                onPaletteRequested: commandPalette.open()
            }
        }
        Item {
            id: listPane
            x: navigationPane.width
            width: window.listVisible ? Math.min(window.noteListWidth, window.width - navigationPane.width - 390) : 0
            height: parent.height
            clip: true
            Behavior on width { NumberAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
            NoteList {
                id: noteList
                width: Math.max(220,listPane.width); height: parent.height
                visible: listPane.width > 200
                onArchiveRequested: function(id) { window.requestArchive(id) }
                onRenameRequested: function(id) { editor.focusTitle() }
                onNewNoteRequested: window.newNote()
            }
        }
        EditorView {
            id: editor
            objectName: "editorView"
            x: navigationPane.width + listPane.width
            width: columns.width - x
            height: parent.height
            sidebarHidden: !window.sidebarVisible || window.sidebarCollapsed
            noteListHidden: !window.listVisible
            onSidebarRequested: {
                window.toggleSidebar()
            }
            onNoteListRequested: window.toggleNoteList()
            onArchiveRequested: function(id) { window.requestArchive(id) }
            onShareRequested: shareMenu.popup(window.width - 228, 130)
        }
        MouseArea {
            x: navigationPane.width + listPane.width - 3
            width: 6; height: parent.height
            visible: window.listVisible
            cursorShape: Qt.SplitHCursor
            property real startX: 0
            property real startWidth: 0
            onPressed: function(mouse) { startX=mapToItem(columns,mouse.x,0).x; startWidth=window.noteListWidth }
            onPositionChanged: function(mouse) { if(pressed) window.noteListWidth=Math.max(240,Math.min(390,startWidth+mapToItem(columns,mouse.x,0).x-startX)) }
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: parent.height; color: Theme.accent; opacity: parent.pressed?0.5:0 }
        }
    }
    CommandPalette { id: commandPalette; objectName: "commandPalette"; onCommandTriggered: function(command) { window.executeCommand(command) } }
    SettingsDialog { id: settingsDialog; objectName: "settingsDialog"; onClosed: editor.focusBody() }
    Popup {
        id: sidebarDrawer
        objectName: "sidebarDrawer"
        parent: Overlay.overlay
        x: 0; y: titleBar.height
        width: 216; height: window.height-titleBar.height
        padding: 0; modal: true; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        Overlay.modal: Rectangle { color: "#66000000" }
        background: Rectangle { color: Theme.sidebar; border.color: Theme.border }
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
                NumberAnimation { property: "x"; from: -16; to: 0; duration: 180; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 120 } }
        contentItem: Sidebar {
            collapsed: false
            onNewNoteRequested: { sidebarDrawer.close(); window.newNote() }
            onSettingsRequested: { sidebarDrawer.close(); settingsDialog.open() }
            onPaletteRequested: { sidebarDrawer.close(); commandPalette.open() }
        }
    }
    Popup {
        id: noteDrawer
        objectName: "noteDrawer"
        parent: Overlay.overlay
        x: window.sidebarVisible?64:0; y: titleBar.height
        width: 300; height: window.height-titleBar.height
        padding: 0; modal: true; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        Overlay.modal: Rectangle { color: "#66000000" }
        background: Rectangle { color: Theme.bg; border.color: Theme.border }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 } }
        exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 120 } }
        contentItem: NoteList {
            id: drawerNoteList
            onArchiveRequested: function(id) { window.requestArchive(id) }
            onRenameRequested: { noteDrawer.close(); editor.focusTitle() }
            onNewNoteRequested: { noteDrawer.close(); window.newNote() }
            onNoteSelected: { noteDrawer.close(); editor.focusBody() }
        }
    }
    Toast { id: toast; objectName: "toast"; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.rightMargin: 26; anchors.bottomMargin: 57 }
    AuroraMenu {
        id: shareMenu
        Action { text: "Copy as Markdown"; onTriggered: { notes.copyNote(); toast.show("Note copied to clipboard") } }
        Action { text: "Export Markdown…"; onTriggered: exportDialog.open() }
    }
    FileDialog {
        id: exportDialog
        title: "Export note"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Markdown files (*.md)"]
        defaultSuffix: "md"
        onAccepted: if(notes.exportNote(selectedFile)) toast.show("Note exported")
    }
    Popup {
        id: archiveDialog
        parent: Overlay.overlay
        x: (parent.width-width)/2; y: (parent.height-height)/2
        width: 370; padding: 25
        modal: true; focus: true
        background: Rectangle { color: Theme.surface; radius: 10; border.color: Theme.border }
        Overlay.modal: Rectangle { color: "#66000000" }
        contentItem: ColumnLayout {
            spacing: 15
            Text { text: "Archive this note?"; color: Theme.text; font.pixelSize: 18; font.weight: Font.DemiBold }
            Text { Layout.fillWidth: true; text: "You can find and restore it from Archive."; color: Theme.secondary; font.pixelSize: 12; wrapMode: Text.WordWrap }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                AuroraButton { text: "Cancel"; onClicked: archiveDialog.close() }
                AuroraButton { text: "Archive"; quiet: false; onClicked: { notes.archiveNote(window.pendingArchiveId); archiveDialog.close(); toast.show("Note archived") } }
            }
        }
    }
    // Thin edge hit areas preserve native desktop resizing on the custom window chrome.
    Repeater {
        model: [Qt.LeftEdge,Qt.RightEdge,Qt.TopEdge,Qt.BottomEdge]
        MouseArea {
            required property int modelData
            width: modelData===Qt.LeftEdge||modelData===Qt.RightEdge?4:window.width-12
            height: modelData===Qt.TopEdge||modelData===Qt.BottomEdge?4:window.height-12
            x: modelData===Qt.RightEdge?window.width-4:modelData===Qt.LeftEdge?0:6
            y: modelData===Qt.BottomEdge?window.height-4:modelData===Qt.TopEdge?0:6
            cursorShape: modelData===Qt.TopEdge||modelData===Qt.BottomEdge?Qt.SizeVerCursor:Qt.SizeHorCursor
            onPressed: window.startSystemResize(modelData)
        }
    }
}
