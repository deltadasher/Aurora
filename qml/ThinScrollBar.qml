import QtQuick
import QtQuick.Controls

ScrollBar {
    id: bar
    padding: 2
    policy: ScrollBar.AsNeeded
    implicitWidth: 8
    contentItem: Rectangle {
        implicitWidth: 4; implicitHeight: 4; radius: 2
        color: bar.pressed ? Theme.accent : bar.hovered ? Theme.secondary : Theme.border
        opacity: bar.size < 1 ? (bar.active || bar.hovered ? 1 : 0.45) : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }
    background: Rectangle { color: "transparent" }
}
