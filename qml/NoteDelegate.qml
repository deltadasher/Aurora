import QtQuick
import QtQuick.Controls

ItemDelegate {
    id: row
    property string noteId: ""
    property string noteTitle: ""
    property string preview: ""
    property string edited: ""
    property string workspaceName: ""
    property bool favorite: false
    property bool selected: false
    signal activated()
    signal menuRequested(real mouseX, real mouseY)

    objectName: "noteRow_" + noteId
    height: Theme.compact ? 104 : 124
    padding: 0
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: (noteTitle || "Untitled") + (favorite ? ", favorite" : "")
    Accessible.description: (selected ? "Selected note. " : "") + preview
    onClicked: activated()

    background: Item {
        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 3
            anchors.bottomMargin: 3
            radius: 7
            color: row.down ? Theme.hover : row.selected ? Theme.surface : row.hovered ? Theme.hover : "transparent"
            border.width: row.activeFocus ? 1 : 0
            border.color: Theme.accent
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
        Rectangle {
            x: 10
            width: 2
            height: 26
            anchors.verticalCenter: parent.verticalCenter
            radius: 1
            color: Theme.accent
            opacity: row.selected ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        }
        Rectangle {
            x: 25
            y: parent.height - 1
            width: parent.width - 50
            height: 1
            color: Theme.border
            opacity: row.selected || row.hovered ? 0 : 0.4
        }
    }

    contentItem: Item {
        Text {
            id: titleText
            x: 25
            y: Theme.compact ? 15 : 19
            width: parent.width - 72
            text: row.noteTitle || "Untitled"
            color: row.selected ? Theme.text : Theme.text
            font.family: Theme.uiFont
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Text {
            x: 25
            y: Theme.compact ? 37 : 42
            width: parent.width - 50
            text: row.preview || "Start writing…"
            color: row.preview ? Theme.secondary : Theme.muted
            font.family: Theme.uiFont
            font.pixelSize: 12
            lineHeight: 1.45
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        Text {
            x: 25
            y: parent.height - 27
            width: parent.width - 71
            text: row.edited
            color: Theme.muted
            font.family: Theme.uiFont
            font.pixelSize: 10
            elide: Text.ElideRight
        }
        Icon {
            name: "star"
            size: 12
            x: parent.width - 39
            y: parent.height - 27
            color: Theme.accent
            visible: row.favorite
        }
        AuroraButton {
            id: moreButton
            width: 24
            height: 24
            x: parent.width - 39
            y: Theme.compact ? 11 : 15
            iconName: "more"
            tooltip: "Note actions"
            opacity: row.hovered || row.activeFocus || hovered || activeFocus ? 1 : 0
            enabled: opacity > 0
            onClicked: row.menuRequested(x + width / 2, y + height)
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) { row.menuRequested(mouse.x, mouse.y) }
    }
}
