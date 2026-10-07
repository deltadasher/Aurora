import QtQuick
import QtQuick.Controls

Item {
    id: root
    objectName: "sidebar"
    property bool collapsed: false
    signal settingsRequested()
    signal newNoteRequested()
    signal paletteRequested()

    readonly property var mainNavigation: [
        { label: "All Notes", icon: "all", objectName: "navAllNotes" },
        { label: "Favorites", icon: "star", objectName: "navFavorites" },
        { label: "Recent", icon: "clock", objectName: "navRecent" },
        { label: "Archive", icon: "archive", objectName: "navArchive" }
    ]
    readonly property var workspaces: [
        { label: "Personal", icon: "personal", objectName: "navPersonal" },
        { label: "Design", icon: "design", objectName: "navDesign" },
        { label: "Research", icon: "research", objectName: "navResearch" },
        { label: "Ideas", icon: "idea", objectName: "navIdeas" }
    ]

    Rectangle {
        anchors.fill: parent
        color: Theme.sidebar
        Behavior on color { ColorAnimation { duration: Theme.motion } }
    }
    Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border; opacity: 0.7 }

    Item {
        id: brand
        x: root.collapsed ? 18 : 24
        y: 29
        height: 28
        width: parent.width - x - 20
        Icon { name: "aurora"; size: 27; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
        Text {
            x: 38
            anchors.verticalCenter: parent.verticalCenter
            text: "Aurora"
            font.family: Theme.uiFont
            font.pixelSize: 20
            font.weight: Font.DemiBold
            font.letterSpacing: -0.6
            color: Theme.text
            visible: !root.collapsed
        }
    }

    ItemDelegate {
        id: newNote
        objectName: "newNoteButton"
        x: 12
        y: 83
        width: parent.width - 24
        height: 35
        hoverEnabled: true
        padding: 0
        focusPolicy: Qt.StrongFocus
        Accessible.name: "New note"
        onClicked: root.newNoteRequested()
        background: Rectangle {
            radius: 6
            color: newNote.down ? Theme.hover : newNote.hovered ? Theme.hover : Theme.surface
            border.width: 1
            border.color: newNote.activeFocus ? Theme.accent : Theme.border
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
        contentItem: Item {
            Icon { name: "plus"; size: 16; x: root.collapsed ? (parent.width - 16) / 2 : 12; anchors.verticalCenter: parent.verticalCenter; color: Theme.accent }
            Text { x: 37; anchors.verticalCenter: parent.verticalCenter; text: "New note"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: 12; visible: !root.collapsed }
            Text { anchors.right: parent.right; anchors.rightMargin: 11; anchors.verticalCenter: parent.verticalCenter; text: "Ctrl N"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 9; visible: !root.collapsed }
        }
        AuroraToolTip {
            parent: newNote
            visible: root.collapsed && newNote.hovered
            text: "New note · Ctrl+N"
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }

    Column {
        id: navigation
        x: 9
        y: root.height < 690 ? 132 : 142
        width: parent.width - 18
        spacing: 3
        Repeater {
            model: root.mainNavigation
            delegate: navigationDelegate
        }
    }
    Text {
        id: workspaceLabel
        x: 25
        y: navigation.y + navigation.height + (root.height < 690 ? 22 : 30)
        text: "WORKSPACES"
        font.family: Theme.uiFont
        font.pixelSize: 9
        font.weight: Font.Medium
        font.letterSpacing: 1.2
        color: Theme.muted
        visible: !root.collapsed
    }
    Rectangle {
        x: 22
        y: workspaceLabel.y + 4
        width: parent.width - 44
        height: 1
        color: Theme.border
        visible: root.collapsed
    }
    Column {
        x: 9
        y: workspaceLabel.y + 26
        width: parent.width - 18
        spacing: 3
        Repeater {
            model: root.workspaces
            delegate: navigationDelegate
        }
    }

    Component {
        id: navigationDelegate
        ItemDelegate {
            id: navItem
            required property var modelData
            readonly property bool selected: notes.workspace === modelData.label
            width: parent.width
            height: Theme.compact || root.height < 690 ? 32 : 37
            objectName: modelData.objectName
            padding: 0
            hoverEnabled: true
            focusPolicy: Qt.StrongFocus
            Accessible.name: modelData.label
            Accessible.checkable: true
            Accessible.checked: selected
            onClicked: notes.workspace = modelData.label
            background: Rectangle {
                radius: 6
                color: navItem.down ? Theme.hover : navItem.selected ? Theme.hover : navItem.hovered ? Theme.surface : "transparent"
                border.width: navItem.activeFocus ? 1 : 0
                border.color: Theme.accent
                Behavior on color { ColorAnimation { duration: Theme.fast } }
                Rectangle {
                    x: 0
                    width: 2
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 1
                    color: Theme.accent
                    visible: navItem.selected
                }
            }
            contentItem: Item {
                Icon {
                    name: navItem.modelData.icon
                    size: 17
                    x: root.collapsed ? (parent.width - 17) / 2 : 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: navItem.selected ? Theme.accent : navItem.hovered ? Theme.text : Theme.secondary
                }
                Text {
                    x: 42
                    width: parent.width - 76
                    anchors.verticalCenter: parent.verticalCenter
                    text: navItem.modelData.label
                    elide: Text.ElideRight
                    color: navItem.selected ? Theme.text : Theme.secondary
                    font.family: Theme.uiFont
                    font.pixelSize: 12
                    font.weight: navItem.selected ? Font.Medium : Font.Normal
                    visible: !root.collapsed
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: notes.counts[navItem.modelData.label] || ""
                    color: Theme.muted
                    font.family: Theme.uiFont
                    font.pixelSize: 10
                    visible: !root.collapsed
                }
            }
            AuroraToolTip {
                parent: navItem
                visible: root.collapsed && navItem.hovered
                text: navItem.modelData.label
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
    }

    Column {
        id: bottomActions
        x: 12
        width: parent.width - 24
        anchors.bottom: userArea.top
        anchors.bottomMargin: 15
        spacing: 3
        AuroraButton {
            width: parent.width
            height: 34
            iconName: "search"
            text: root.collapsed ? "" : "Quick command"
            tooltip: "Quick command · Ctrl+K"
            visible: root.height > 760
            onClicked: root.paletteRequested()
        }
        AuroraButton {
            objectName: "settingsButton"
            width: parent.width
            height: 34
            iconName: "settings"
            text: root.collapsed ? "" : "Settings"
            tooltip: "Settings"
            onClicked: root.settingsRequested()
        }
    }
    ItemDelegate {
        id: userArea
        x: 0
        anchors.bottom: parent.bottom
        width: parent.width
        height: 76
        padding: 0
        hoverEnabled: true
        Accessible.name: "Alex Morgan, local workspace settings"
        onClicked: root.settingsRequested()
        background: Rectangle {
            color: userArea.hovered || userArea.down ? Theme.surface : "transparent"
            border.width: userArea.activeFocus ? 1 : 0
            border.color: Theme.accent
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Rectangle { width: parent.width; height: 1; color: Theme.border; opacity: 0.7 }
        }
        contentItem: Item {
            Rectangle {
                x: root.collapsed ? (parent.width - 30) / 2 : 24
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                radius: 9
                color: Theme.accentSoft
                Text { anchors.centerIn: parent; text: "AM"; color: Theme.accent; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.DemiBold }
            }
            Column {
                x: 64
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                visible: !root.collapsed
                Text { text: "Alex Morgan"; color: Theme.text; font.family: Theme.uiFont; font.pixelSize: 11; font.weight: Font.Medium }
                Row {
                    spacing: 5
                    Rectangle { width: 4; height: 4; radius: 2; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Local workspace"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 9 }
                }
            }
            Icon { anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; name: "chevronDown"; size: 12; color: Theme.muted; visible: !root.collapsed }
        }
        AuroraToolTip {
            parent: userArea
            visible: root.collapsed && userArea.hovered
            text: "Alex Morgan · Local workspace"
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }
}
