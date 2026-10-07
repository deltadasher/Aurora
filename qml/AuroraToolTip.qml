import QtQuick
import QtQuick.Controls

ToolTip {
    id: control
    delay: 650
    timeout: 3500
    leftPadding: 10
    rightPadding: 10
    topPadding: 7
    bottomPadding: 7
    margins: 8
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: -height - 7
    font.family: Theme.uiFont
    font.pixelSize: 11
    contentItem: Text {
        text: control.text
        font: control.font
        color: Theme.text
        wrapMode: Text.NoWrap
    }
    background: Rectangle {
        color: Theme.surface
        radius: 5
        border.width: 1
        border.color: Theme.border
    }
    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 100 } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 80 } }
}
