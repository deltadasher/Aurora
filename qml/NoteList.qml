import QtQuick
import QtQuick.Controls

Item {
    id: root
    objectName: "noteList"
    signal archiveRequested(string id)
    signal renameRequested(string id)
    signal newNoteRequested()
    signal noteSelected()
    property string contextNoteId: ""
    property bool contextFavorite: false

    function focusSearch() {
        searchField.forceActiveFocus()
        searchField.selectAll()
    }

    function openNoteMenu(noteId, favorite, px, py) {
        root.contextNoteId = noteId
        root.contextFavorite = favorite
        noteMenu.popup(px, py)
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        Behavior on color { ColorAnimation { duration: Theme.motion } }
    }
    Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border; opacity: 0.8 }

    Item {
        id: header
        x: 24
        y: 30
        width: parent.width - 48
        height: 35
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 37
            text: notes.workspace
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: 19
            font.weight: Font.DemiBold
            font.letterSpacing: -0.4
            elide: Text.ElideRight
        }
        AuroraButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            iconName: "plus"
            tooltip: "New note · Ctrl+N"
            onClicked: root.newNoteRequested()
        }
    }

    Row {
        id: searchRow
        x: 24
        y: 83
        width: parent.width - 48
        height: 35
        spacing: 6
        Item {
            width: parent.width - 38
            height: 35
            TextField {
                id: searchField
                objectName: "searchField"
                anchors.fill: parent
                text: notes.query
                placeholderText: "Search notes…"
                placeholderTextColor: Theme.muted
                color: Theme.text
                selectionColor: Theme.accentSoft
                selectedTextColor: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: 11
                leftPadding: 30
                rightPadding: text.length ? 27 : 9
                topPadding: 0
                bottomPadding: 0
                selectByMouse: true
                Accessible.name: "Search notes"
                onTextEdited: notes.query = text
                Keys.onEscapePressed: {
                    notes.query = ""
                    focus = false
                }
                background: Rectangle {
                    radius: 6
                    color: Theme.surface
                    border.width: 1
                    border.color: searchField.activeFocus ? Theme.accent : Theme.border
                    Behavior on color { ColorAnimation { duration: Theme.motion } }
                    Behavior on border.color { ColorAnimation { duration: Theme.fast } }
                }
            }
            Icon { name: "search"; size: 13; x: 10; anchors.verticalCenter: parent.verticalCenter; color: searchField.activeFocus ? Theme.accent : Theme.muted }
            AuroraButton {
                anchors.right: parent.right
                anchors.rightMargin: 3
                anchors.verticalCenter: parent.verticalCenter
                width: 23
                height: 24
                iconName: "close"
                tooltip: "Clear search"
                visible: searchField.text.length > 0
                onClicked: { notes.query = ""; searchField.forceActiveFocus() }
            }
        }
        AuroraButton {
            id: filterButton
            objectName: "filterButton"
            width: 32
            height: 35
            iconName: "filter"
            selected: notes.favoritesOnly
            tooltip: "Filter and sort"
            onClicked: filterMenu.popup(searchRow.x + searchRow.width - filterMenu.width, searchRow.y + searchRow.height + 6)
        }
    }

    Row {
        id: listCaption
        x: 25
        y: 143
        width: parent.width - 50
        spacing: 5
        Text { text: notes.query ? "SEARCH RESULTS" : "YOUR NOTES"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 9; font.letterSpacing: 1 }
        Text { text: "· " + notes.noteCount; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 9 }
    }
    ListView {
        id: noteView
        x: 0
        y: 168
        width: parent.width
        height: parent.height - y - 41
        clip: true
        model: notes.model
        boundsBehavior: Flickable.StopAtBounds
        reuseItems: false
        keyNavigationEnabled: true
        focus: false
        ScrollBar.vertical: ThinScrollBar { }
        delegate: NoteDelegate {
            width: noteView.width
            noteId: model.noteId
            noteTitle: model.title
            preview: model.preview
            edited: model.edited
            favorite: model.favorite
            workspaceName: model.workspaceName
            selected: noteId === notes.selectedId
            onActivated: {
                noteView.currentIndex = index
                notes.selectNote(noteId)
                root.noteSelected()
            }
            onMenuRequested: function(mouseX, mouseY) {
                var point = mapToItem(root, mouseX, mouseY)
                root.openNoteMenu(noteId, favorite, point.x, point.y)
            }
            Keys.onUpPressed: {
                noteView.decrementCurrentIndex()
                if (noteView.currentItem) {
                    notes.selectNote(noteView.currentItem.noteId)
                    noteView.currentItem.forceActiveFocus()
                }
            }
            Keys.onDownPressed: {
                noteView.incrementCurrentIndex()
                if (noteView.currentItem) {
                    notes.selectNote(noteView.currentItem.noteId)
                    noteView.currentItem.forceActiveFocus()
                }
            }
        }
        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
                NumberAnimation { property: "height"; from: 0; to: Theme.compact ? 104 : 124; duration: 180; easing.type: Easing.OutCubic }
            }
        }
        addDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic } }
        removeDisplaced: Transition { NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic } }
    }

    Column {
        anchors.centerIn: noteView
        width: parent.width - 52
        spacing: 12
        visible: noteView.count === 0
        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: notes.query ? "search" : "all"; size: 26; color: Theme.muted }
        Text {
            width: parent.width
            text: notes.query ? "No notes found" : notes.workspace === "Archive" ? "Your archive is empty" : "A little room to think"
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: 13
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        Text {
            width: parent.width
            text: notes.query ? "Try a different word, or clear your search." : notes.workspace === "Archive" ? "Archived notes will appear here." : "Capture your first thought in a new note."
            color: Theme.secondary
            font.family: Theme.uiFont
            font.pixelSize: 11
            lineHeight: 1.4
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        AuroraButton {
            anchors.horizontalCenter: parent.horizontalCenter
            text: notes.query ? "Clear search" : "New note"
            iconName: notes.query ? "close" : "plus"
            visible: notes.query.length > 0 || notes.workspace !== "Archive"
            onClicked: { if (notes.query) notes.query = ""; else root.newNoteRequested() }
        }
    }
    Item {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 41
        Rectangle { width: parent.width; height: 1; color: Theme.border; opacity: 0.6 }
        Text {
            x: 25
            anchors.verticalCenter: parent.verticalCenter
            text: notes.noteCount + (notes.noteCount === 1 ? " note" : " notes")
            color: Theme.muted
            font.family: Theme.uiFont
            font.pixelSize: 10
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: notes.saveStatus
            color: Theme.muted
            font.family: Theme.uiFont
            font.pixelSize: 9
        }
    }

    AuroraMenu {
        id: filterMenu
        AuroraMenuItem { text: "Favorites only"; checkable: true; checked: notes.favoritesOnly; onTriggered: notes.favoritesOnly = !notes.favoritesOnly }
        AuroraMenuSeparator { }
        AuroraMenuItem { text: "Recently edited"; checkable: true; checked: notes.sortMode === "edited"; onTriggered: notes.sortMode = "edited" }
        AuroraMenuItem { text: "Title A–Z"; checkable: true; checked: notes.sortMode === "title"; onTriggered: notes.sortMode = "title" }
    }
    AuroraMenu {
        id: noteMenu
        AuroraMenuItem { text: "Rename"; onTriggered: { notes.selectNote(root.contextNoteId); root.renameRequested(root.contextNoteId) } }
        AuroraMenuItem { text: "Duplicate"; onTriggered: notes.duplicateNote(root.contextNoteId) }
        AuroraMenuItem { text: root.contextFavorite ? "Remove favorite" : "Add to favorites"; onTriggered: notes.toggleFavoriteFor(root.contextNoteId) }
        AuroraMenu {
            title: "Move to…"
            AuroraMenuItem { text: "Personal"; onTriggered: notes.moveNote(root.contextNoteId, "Personal") }
            AuroraMenuItem { text: "Design"; onTriggered: notes.moveNote(root.contextNoteId, "Design") }
            AuroraMenuItem { text: "Research"; onTriggered: notes.moveNote(root.contextNoteId, "Research") }
            AuroraMenuItem { text: "Ideas"; onTriggered: notes.moveNote(root.contextNoteId, "Ideas") }
        }
        AuroraMenuSeparator { }
        AuroraMenuItem {
            text: notes.workspace === "Archive" ? "Restore note" : "Archive note"
            onTriggered: {
                if (notes.workspace === "Archive") notes.restoreNote(root.contextNoteId)
                else root.archiveRequested(root.contextNoteId)
            }
        }
    }
}
