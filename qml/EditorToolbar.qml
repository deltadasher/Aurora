import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var handler
    signal linkRequested()
    implicitHeight: 44

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        AuroraButton {
            objectName: "boldButton"
            iconName: "bold"
            tooltip: "Bold · Ctrl+B"
            selected: root.handler ? root.handler.bold : false
            focusPolicy: Qt.TabFocus
            onClicked: if (root.handler) root.handler.toggleBold()
        }
        AuroraButton {
            objectName: "italicButton"
            iconName: "italic"
            tooltip: "Italic · Ctrl+I"
            selected: root.handler ? root.handler.italic : false
            focusPolicy: Qt.TabFocus
            onClicked: if (root.handler) root.handler.toggleItalic()
        }
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 17
            Layout.leftMargin: 7
            Layout.rightMargin: 7
            color: Theme.border
        }
        AuroraButton {
            id: headingButton
            objectName: "headingButton"
            iconName: "heading"
            tooltip: "Heading"
            selected: root.handler ? root.handler.heading > 0 : false
            focusPolicy: Qt.TabFocus
            onClicked: headingMenu.popup(0, height + 5)
            AuroraMenu {
                id: headingMenu
                Action { text: "Paragraph"; onTriggered: root.handler.setHeading(0) }
                Action { text: "Heading 1"; onTriggered: root.handler.setHeading(1) }
                Action { text: "Heading 2"; onTriggered: root.handler.setHeading(2) }
                Action { text: "Heading 3"; onTriggered: root.handler.setHeading(3) }
            }
        }
        AuroraButton {
            objectName: "quoteButton"
            iconName: "quote"
            tooltip: "Quote"
            focusPolicy: Qt.TabFocus
            onClicked: if (root.handler) root.handler.toggleQuote()
        }
        AuroraButton {
            objectName: "bulletsButton"
            iconName: "bullets"
            tooltip: "Bulleted list"
            focusPolicy: Qt.TabFocus
            onClicked: if (root.handler) root.handler.toggleBullets()
        }
        AuroraButton {
            objectName: "numbersButton"
            iconName: "numbers"
            tooltip: "Numbered list"
            focusPolicy: Qt.TabFocus
            onClicked: if (root.handler) root.handler.toggleNumbers()
        }
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 17
            Layout.leftMargin: 7
            Layout.rightMargin: 7
            color: Theme.border
        }
        AuroraButton {
            objectName: "codeButton"
            iconName: "code"
            tooltip: "Inline code"
            focusPolicy: Qt.TabFocus
            onClicked: if (root.handler) root.handler.toggleCode()
        }
        AuroraButton {
            objectName: "linkButton"
            iconName: "link"
            tooltip: "Add a link"
            focusPolicy: Qt.TabFocus
            onClicked: root.linkRequested()
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.border
        opacity: 0.6
    }
}
