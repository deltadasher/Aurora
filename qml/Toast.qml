import QtQuick

Item {
    id: toast
    objectName: "archiveToast"
    property string message: "Note archived"
    property bool showing: false
    width: Math.min(340, label.implicitWidth + 96)
    height: 48
    anchors.right: parent ? parent.right : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.rightMargin: 28
    anchors.bottomMargin: 24
    z: 1000
    visible: opacity > 0
    opacity: showing ? 1 : 0
    transform: Translate { y: toast.showing ? 0 : 6; Behavior on y { NumberAnimation { duration: Theme.motion - 20; easing.type: Easing.OutCubic } } }
    Behavior on opacity { NumberAnimation { duration: Theme.motion - 20; easing.type: Easing.OutCubic } }

    function show(text) {
        message = text
        showing = true
        hideTimer.restart()
    }

    Timer { id: hideTimer; interval: 3200; onTriggered: toast.showing = false }
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 3
        radius: 8
        color: Theme.dark ? "#60000000" : "#16000000"
    }
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Theme.surface
        border.color: Theme.border
        border.width: 1
    }
    Icon {
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        name: "check"
        size: 18
        color: Theme.accent
    }
    Text {
        id: label
        anchors.left: parent.left
        anchors.leftMargin: 45
        anchors.right: dismiss.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: toast.message
        font.family: Theme.uiFont
        font.pixelSize: 13
        color: Theme.text
        elide: Text.ElideRight
        Accessible.role: Accessible.AlertMessage
        Accessible.name: text
    }
    AuroraButton {
        id: dismiss
        anchors.right: parent.right
        anchors.rightMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 30
        iconName: "close"
        tooltip: "Dismiss notification"
        onClicked: toast.showing = false
    }
}
