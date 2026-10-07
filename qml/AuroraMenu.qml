import QtQuick
import QtQuick.Controls

Menu {
    id: menu
    padding: 5
    implicitWidth: 212
    font.family: Theme.uiFont
    font.pixelSize: 12
    background: Rectangle { color: Theme.surface; radius: 8; border.color: Theme.border }
    delegate: AuroraMenuItem { }
    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 100 } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 80 } }
}
