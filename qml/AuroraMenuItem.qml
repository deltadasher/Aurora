import QtQuick
import QtQuick.Controls

MenuItem {
    id: control
    implicitWidth: 204
    implicitHeight: 34
    leftPadding: checkable ? 33 : 12
    rightPadding: subMenu ? 31 : 12
    topPadding: 0
    bottomPadding: 0
    hoverEnabled: true
    font.family: Theme.uiFont
    font.pixelSize: 12
    focusPolicy: Qt.StrongFocus
    Accessible.name: text

    background: Rectangle {
        radius: 5
        color: control.down ? Theme.border : control.highlighted || control.hovered ? Theme.hover : "transparent"
        border.width: control.visualFocus ? 1 : 0
        border.color: Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }
    contentItem: Text {
        text: control.text
        font: control.font
        color: !control.enabled ? Theme.muted : control.highlighted || control.hovered ? Theme.text : Theme.secondary
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    indicator: Item {
        x: 12
        y: (control.height - height) / 2
        width: 14
        height: 18
        visible: control.checkable
        Text {
            anchors.centerIn: parent
            text: "✓"
            font.family: Theme.uiFont
            font.pixelSize: 12
            color: Theme.accent
            visible: control.checked
        }
    }
    arrow: Icon {
        name: "chevronRight"
        size: 13
        color: Theme.secondary
        visible: !!control.subMenu
        x: control.width - 24
        y: (control.height - 13) / 2
    }
    HoverHandler { cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
}
