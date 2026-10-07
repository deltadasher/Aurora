import QtQuick
import QtQuick.Controls

Button {
    id: control
    property string iconName: ""
    property string tooltip: text
    property bool quiet: true
    property bool selected: false
    hoverEnabled: true
    implicitWidth: text.length ? contentItem.implicitWidth + 24 : 32
    implicitHeight: 32
    padding: 8
    spacing: 7
    font.family: Theme.uiFont; font.pixelSize: 12
    focusPolicy: Qt.StrongFocus
    Accessible.name: tooltip || text
    opacity: enabled ? 1 : 0.38
    contentItem: Row {
        spacing: control.spacing
        anchors.centerIn: parent
        height: 18
        transform: Translate { y: control.down ? 1 : 0 }
        Icon { name: control.iconName; size: 16; visible: !!control.iconName; anchors.verticalCenter: parent.verticalCenter; color: !control.quiet ? Theme.bg : control.selected ? Theme.accent : control.hovered ? Theme.text : Theme.secondary }
        Text { id: label; visible: !!control.text.length; text: control.text; font: control.font; anchors.verticalCenter: parent.verticalCenter; color: !control.quiet ? Theme.bg : control.selected ? Theme.accent : Theme.text }
    }
    background: Rectangle {
        radius: 6
        color: !control.quiet ? (control.down ? Qt.darker(Theme.accent,1.12) : control.hovered ? Qt.lighter(Theme.accent,1.07) : Theme.accent) : control.selected ? Theme.accentSoft : control.down ? Theme.border : control.hovered ? Theme.hover : "transparent"
        border.width: control.visualFocus ? 1 : 0
        border.color: Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }
    AuroraToolTip {
        parent: control
        visible: control.hovered && control.tooltip.length > 0
        text: control.tooltip
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
