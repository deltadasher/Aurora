pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

Popup {
    id: commandPaletteRoot
    objectName: "commandPalette"
    parent: Overlay.overlay
    width: Math.min(560, parent ? parent.width - 48 : 560)
    height: 66 + 34 + Math.max(110, Math.min(350, filteredCommands.length * 48)) + 48
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0
    padding: 0
    modal: true
    dim: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    signal commandTriggered(string command)
    property string modifier: Qt.platform.os === "osx" ? "⌘" : "Ctrl"
    property var commands: [
        { code: "new", label: "New note", icon: "plus", hint: modifier + "+N" },
        { code: "search", label: "Search notes", icon: "search", hint: modifier + "+F" },
        { code: "sidebar", label: "Toggle sidebar", icon: "sidebar", hint: modifier + "+Shift+\\" },
        { code: "list", label: "Toggle note list", icon: "list", hint: "" },
        { code: "theme", label: "Switch theme", icon: "sun", hint: "" },
        { code: "settings", label: "Open settings", icon: "settings", hint: modifier + "+," },
        { code: "archive", label: "Archive note", icon: "archive", hint: "" }
    ]
    property var filteredCommands: commands.filter(function(command) {
        return command.label.toLowerCase().indexOf(commandSearch.text.trim().toLowerCase()) !== -1
    })

    function runCurrent() {
        if (commandList.currentIndex >= 0 && commandList.currentIndex < filteredCommands.length) {
            const command = filteredCommands[commandList.currentIndex].code
            close()
            commandTriggered(command)
        }
    }

    onOpened: {
        commandSearch.text = ""
        commandList.currentIndex = 0
        commandSearch.forceActiveFocus()
    }

    Overlay.modal: Rectangle { color: Theme.dark ? "#80080A0B" : "#550E1011" }
    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.motion - 20; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.98; to: 1; duration: Theme.motion - 20; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast } }

    background: Rectangle {
        radius: 12
        color: Theme.surface
        border.color: Theme.border
        border.width: 1
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 5
            z: -1
            radius: parent.radius
            color: Theme.dark ? "#65000000" : "#16000000"
        }
    }

    contentItem: Item {
        Item {
            id: searchHeader
            width: parent.width
            height: 66
            Icon {
                anchors.left: parent.left
                anchors.leftMargin: 23
                anchors.verticalCenter: parent.verticalCenter
                name: "search"
                size: 21
                color: Theme.secondary
            }
            TextField {
                id: commandSearch
                objectName: "commandSearch"
                anchors.left: parent.left
                anchors.leftMargin: 58
                anchors.right: escapeHint.left
                anchors.rightMargin: 15
                anchors.verticalCenter: parent.verticalCenter
                height: 46
                padding: 0
                font.family: Theme.uiFont
                font.pixelSize: 16
                color: Theme.text
                placeholderText: "Search commands…"
                placeholderTextColor: Theme.muted
                selectionColor: Theme.accent
                selectedTextColor: Theme.bg
                background: null
                Accessible.name: "Search commands"
                onTextChanged: commandList.currentIndex = commandPaletteRoot.filteredCommands.length ? 0 : -1
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Down && commandPaletteRoot.filteredCommands.length) {
                        commandList.currentIndex = (commandList.currentIndex + 1) % commandPaletteRoot.filteredCommands.length
                        commandList.positionViewAtIndex(commandList.currentIndex, ListView.Contain)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up && commandPaletteRoot.filteredCommands.length) {
                        commandList.currentIndex = (commandList.currentIndex - 1 + commandPaletteRoot.filteredCommands.length) % commandPaletteRoot.filteredCommands.length
                        commandList.positionViewAtIndex(commandList.currentIndex, ListView.Contain)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        commandPaletteRoot.runCurrent()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        commandPaletteRoot.close()
                        event.accepted = true
                    }
                }
            }
            Rectangle {
                id: escapeHint
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 23
                radius: 4
                color: "transparent"
                border.color: Theme.border
                Text { anchors.centerIn: parent; text: "esc"; font.family: Theme.uiFont; font.pixelSize: 10; color: Theme.muted }
            }
        }
        Rectangle { x: 0; y: 66; width: parent.width; height: 1; color: Theme.border }
        Text {
            x: 22
            y: 80
            text: commandSearch.text.length ? "MATCHING COMMANDS" : "QUICK ACTIONS"
            font.family: Theme.uiFont
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 1.1
            color: Theme.muted
        }
        ListView {
            id: commandList
            x: 10
            y: 100
            width: parent.width - 20
            height: parent.height - y - 48
            clip: true
            model: commandPaletteRoot.filteredCommands
            currentIndex: 0
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ThinScrollBar {}
            delegate: Button {
                id: commandButton
                required property var modelData
                required property int index
                width: commandList.width
                height: 48
                padding: 0
                hoverEnabled: true
                focusPolicy: Qt.NoFocus
                Accessible.name: modelData.label
                background: Rectangle {
                    radius: 6
                    color: commandButton.down ? Theme.border
                           : commandList.currentIndex === commandButton.index ? Theme.hover
                           : commandButton.hovered ? Theme.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    Rectangle {
                        x: 0; y: 13; width: 2; height: parent.height - 26; radius: 1
                        color: Theme.accent
                        visible: commandList.currentIndex === commandButton.index
                    }
                }
                contentItem: Item {
                    Icon {
                        anchors.left: parent.left
                        anchors.leftMargin: 13
                        anchors.verticalCenter: parent.verticalCenter
                        size: 18
                        name: commandButton.modelData.icon
                        color: commandList.currentIndex === commandButton.index ? Theme.accent : Theme.secondary
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 44
                        anchors.right: shortcutLabel.left
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: commandButton.modelData.label
                        font.family: Theme.uiFont
                        font.pixelSize: 13
                        color: Theme.text
                        elide: Text.ElideRight
                    }
                    Text {
                        id: shortcutLabel
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: commandButton.modelData.hint
                        font.family: Theme.uiFont
                        font.pixelSize: 11
                        color: Theme.muted
                    }
                }
                onClicked: {
                    commandList.currentIndex = index
                    commandPaletteRoot.runCurrent()
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }
        Column {
            anchors.centerIn: commandList
            spacing: 8
            visible: commandPaletteRoot.filteredCommands.length === 0
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No commands found"; font.family: Theme.uiFont; font.pixelSize: 14; color: Theme.text }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Try a different search."; font.family: Theme.uiFont; font.pixelSize: 12; color: Theme.secondary }
        }
        Item {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 43
            Rectangle { width: parent.width; height: 1; color: Theme.border }
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 22
                anchors.verticalCenter: parent.verticalCenter
                text: "↑ ↓  to navigate"
                font.family: Theme.uiFont; font.pixelSize: 11; color: Theme.muted
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 22
                anchors.verticalCenter: parent.verticalCenter
                text: "↵  to select"
                font.family: Theme.uiFont; font.pixelSize: 11; color: Theme.secondary
            }
        }
    }
}
