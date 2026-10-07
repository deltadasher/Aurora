pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: settings
    objectName: "settingsDialog"
    parent: Overlay.overlay
    width: Math.min(690, parent ? parent.width - 48 : 690)
    height: Math.min(600, parent ? parent.height - 48 : 600)
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0
    padding: 0
    modal: true
    dim: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    property int currentTab: 0

    Overlay.modal: Rectangle { color: Theme.dark ? "#80080A0B" : "#550E1011" }
    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.motion - 20; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.985; to: 1; duration: Theme.motion - 20; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast } }
    background: Rectangle {
        radius: 12
        color: Theme.surface
        border.color: Theme.border
        border.width: 1
        Rectangle { anchors.fill: parent; anchors.topMargin: 5; z: -1; radius: 12; color: Theme.dark ? "#60000000" : "#16000000" }
    }

    component ChoiceGroup: Item {
        id: group
        property var choices: []
        property string currentValue: ""
        property string namePrefix: ""
        signal chosen(string value)
        implicitHeight: 40
        Rectangle { anchors.fill: parent; radius: 6; color: Theme.bg; border.color: Theme.border }
        Row {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4
            Repeater {
                model: group.choices
                delegate: Button {
                    id: choiceButton
                    required property string modelData
                    width: (group.width - 8 - (group.choices.length - 1) * 4) / group.choices.length
                    height: group.height - 8
                    padding: 0
                    objectName: group.namePrefix + modelData
                    hoverEnabled: true
                    opacity: enabled ? 1 : 0.45
                    Accessible.name: modelData
                    Accessible.description: group.namePrefix
                    Accessible.checkable: true
                    Accessible.checked: group.currentValue === modelData
                    background: Rectangle {
                        radius: 4
                        color: choiceButton.down ? Theme.border
                               : group.currentValue === choiceButton.modelData ? Theme.surface
                               : choiceButton.hovered ? Theme.hover : "transparent"
                        border.width: 1
                        border.color: choiceButton.activeFocus ? Theme.accent
                                      : group.currentValue === choiceButton.modelData ? Theme.border : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                    }
                    contentItem: Text {
                        text: choiceButton.modelData
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: Theme.uiFont
                        font.pixelSize: 12
                        color: group.currentValue === choiceButton.modelData ? Theme.text : Theme.secondary
                        opacity: choiceButton.enabled ? 1 : 0.45
                    }
                    onClicked: group.chosen(modelData)
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }

    component SettingsToggle: Item {
        id: toggleRow
        property string title: ""
        property string detail: ""
        property alias checked: toggle.checked
        property string controlName: ""
        signal toggled(bool state)
        implicitHeight: 76
        Text {
            x: 0
            y: 16
            width: parent.width - 66
            text: toggleRow.title
            font.family: Theme.uiFont
            font.pixelSize: 13
            color: Theme.text
            elide: Text.ElideRight
        }
        Text {
            x: 0
            y: 39
            width: parent.width - 60
            text: toggleRow.detail
            font.family: Theme.uiFont
            font.pixelSize: 11
            color: Theme.secondary
            wrapMode: Text.WordWrap
        }
        Switch {
            id: toggle
            objectName: toggleRow.controlName
            anchors.right: parent.right
            y: 14
            width: 40
            height: 28
            padding: 0
            hoverEnabled: true
            Accessible.name: toggleRow.title
            Accessible.description: toggleRow.detail
            background: null
            contentItem: null
            indicator: Rectangle {
                x: 0
                y: (toggle.height - height) / 2
                width: 40
                height: 22
                radius: 11
                opacity: toggle.enabled ? 1 : 0.45
                color: toggle.checked ? Theme.accent : toggle.hovered ? Theme.hover : Theme.border
                border.width: 1
                border.color: toggle.activeFocus ? Theme.accent : toggle.checked ? Theme.accent : Theme.muted
                Behavior on color { ColorAnimation { duration: Theme.fast } }
                Rectangle {
                    x: toggle.checked ? 21 : 3
                    y: 3
                    width: 16
                    height: 16
                    radius: 8
                    color: toggle.checked ? "#FFFBF6" : Theme.secondary
                    scale: toggle.down ? 0.9 : 1
                    Behavior on x { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 80 } }
                }
            }
            onToggled: toggleRow.toggled(checked)
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
    }

    component SettingsSlider: Slider {
        id: sliderControl
        implicitHeight: 30
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        hoverEnabled: true
        opacity: enabled ? 1 : 0.45
        background: Rectangle {
            x: sliderControl.leftPadding
            y: sliderControl.topPadding + (sliderControl.availableHeight - height) / 2
            width: sliderControl.availableWidth
            height: 3
            radius: 1.5
            color: Theme.border
            Rectangle { width: sliderControl.visualPosition * parent.width; height: parent.height; radius: 1.5; color: Theme.accent }
        }
        handle: Rectangle {
            x: sliderControl.leftPadding + sliderControl.visualPosition * (sliderControl.availableWidth - width)
            y: sliderControl.topPadding + (sliderControl.availableHeight - height) / 2
            width: 15
            height: 15
            radius: 7.5
            color: sliderControl.pressed || sliderControl.hovered ? Theme.accent : Theme.text
            border.color: sliderControl.activeFocus ? Theme.accent : Theme.surface
            border.width: sliderControl.activeFocus ? 3 : 2
            scale: sliderControl.pressed ? 1.12 : sliderControl.hovered ? 1.04 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }

    contentItem: Item {
        Item {
            id: header
            width: parent.width
            height: 88
            Text { x: 28; y: 22; text: "Settings"; font.family: Theme.uiFont; font.pixelSize: 23; font.weight: Font.DemiBold; color: Theme.text }
            Text { x: 29; y: 54; text: "A space that works the way you do."; font.family: Theme.uiFont; font.pixelSize: 12; color: Theme.secondary }
            AuroraButton {
                anchors.right: parent.right
                anchors.rightMargin: 20
                y: 20
                width: 32
                height: 32
                iconName: "close"
                tooltip: "Close settings"
                onClicked: settings.close()
            }
        }
        Rectangle { y: header.height; width: parent.width; height: 1; color: Theme.border }
        Item {
            id: body
            y: header.height + 1
            width: parent.width
            height: parent.height - y - 59
            Item {
                id: navigation
                width: 158
                height: parent.height
                Rectangle { anchors.fill: parent; color: Theme.sidebar }
                Column {
                    x: 12
                    y: 21
                    width: parent.width - 24
                    spacing: 5
                    Repeater {
                        model: ["Appearance", "Editor", "Behavior"]
                        delegate: Button {
                            id: tabButton
                            required property string modelData
                            required property int index
                            width: parent.width
                            height: 38
                            padding: 0
                            hoverEnabled: true
                            opacity: enabled ? 1 : 0.45
                            objectName: "settingsTab" + modelData
                            Accessible.name: modelData + " settings"
                            Accessible.role: Accessible.PageTab
                            Accessible.selected: settings.currentTab === index
                            background: Rectangle {
                                radius: 5
                                color: tabButton.down ? Theme.border
                                       : settings.currentTab === tabButton.index ? Theme.hover
                                       : tabButton.hovered ? Theme.hover : "transparent"
                                border.width: 1
                                border.color: tabButton.activeFocus ? Theme.accent : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.fast } }
                                Rectangle { x: 0; y: 10; width: 2; height: 18; radius: 1; color: Theme.accent; visible: settings.currentTab === tabButton.index }
                            }
                            contentItem: Item {
                                Icon { x: 11; anchors.verticalCenter: parent.verticalCenter; size: 16; name: ["sun", "heading", "settings"][tabButton.index]; color: settings.currentTab === tabButton.index ? Theme.accent : Theme.secondary }
                                Text { x: 36; anchors.verticalCenter: parent.verticalCenter; text: tabButton.modelData; font.family: Theme.uiFont; font.pixelSize: 12; color: settings.currentTab === tabButton.index ? Theme.text : Theme.secondary }
                            }
                            onClicked: settings.currentTab = index
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
                Column {
                    x: 25
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 24
                    spacing: 7
                    Text { text: "AURORA NOTES"; font.family: Theme.uiFont; font.pixelSize: 9; font.letterSpacing: 1; font.weight: Font.DemiBold; color: Theme.muted }
                    Text { text: "Room for your ideas."; font.family: Theme.uiFont; font.pixelSize: 10; color: Theme.muted }
                }
            }
            Rectangle { x: navigation.width; width: 1; height: parent.height; color: Theme.border }
            StackLayout {
                id: pages
                x: navigation.width + 1
                width: parent.width - x
                height: parent.height
                currentIndex: settings.currentTab

                Flickable {
                    contentWidth: width
                    contentHeight: settingsAppearanceColumn.height + 47
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ThinScrollBar { }
                    Column {
                        id: settingsAppearanceColumn
                        x: 30
                        y: 25
                        width: parent.width - 60
                        spacing: 0
                        Text { text: "Appearance"; font.family: Theme.uiFont; font.pixelSize: 18; font.weight: Font.DemiBold; color: Theme.text }
                        Text { text: "Find your preferred balance of warmth and clarity."; font.family: Theme.uiFont; font.pixelSize: 11; color: Theme.secondary; topPadding: 8; bottomPadding: 26 }
                        Text { text: "Theme"; font.family: Theme.uiFont; font.pixelSize: 12; color: Theme.text; bottomPadding: 10 }
                        ChoiceGroup { width: parent.width; height: 40; choices: ["Dark", "Light", "System"]; currentValue: Theme.themeMode; namePrefix: "theme"; onChosen: function(value) { Theme.themeMode = value } }
                        Text { text: Theme.themeMode === "System" ? "Follows your desktop’s appearance." : Theme.themeMode === "Dark" ? "A quiet canvas for focused work." : "A warm, paper-inspired workspace."; font.family: Theme.uiFont; font.pixelSize: 11; color: Theme.secondary; topPadding: 9; bottomPadding: 26 }
                        Text { text: "Density"; font.family: Theme.uiFont; font.pixelSize: 12; color: Theme.text; bottomPadding: 10 }
                        ChoiceGroup { width: parent.width; height: 40; choices: ["Comfortable", "Compact"]; currentValue: Theme.density; namePrefix: "density"; onChosen: function(value) { Theme.density = value } }
                        Text { text: "Accent"; font.family: Theme.uiFont; font.pixelSize: 12; color: Theme.text; topPadding: 28; bottomPadding: 9 }
                        Row {
                            width: parent.width
                            spacing: 7
                            Repeater {
                                model: ["Warm", "Blue", "Green"]
                                delegate: Button {
                                    id: accentButton
                                    required property string modelData
                                    required property int index
                                    objectName: "accent" + modelData
                                    width: (parent.width - 14) / 3
                                    height: 43
                                    padding: 0
                                    hoverEnabled: true
                                    opacity: enabled ? 1 : 0.45
                                    Accessible.name: modelData + " accent"
                                    Accessible.checkable: true
                                    Accessible.checked: Theme.accentName === modelData
                                    background: Rectangle { radius: 6; color: accentButton.down ? Theme.border : accentButton.hovered || Theme.accentName === accentButton.modelData ? Theme.hover : "transparent"; border.color: accentButton.activeFocus ? Theme.accent : Theme.accentName === accentButton.modelData ? Theme.border : "transparent"; Behavior on color { ColorAnimation { duration: Theme.fast } } }
                                    contentItem: Item {
                                        Rectangle { x: 11; anchors.verticalCenter: parent.verticalCenter; width: 15; height: 15; radius: 7.5; color: ["#DFA56B", "#7DA6C4", "#8DAC90"][accentButton.index] }
                                        Text { x: 35; anchors.verticalCenter: parent.verticalCenter; text: accentButton.modelData; font.family: Theme.uiFont; font.pixelSize: 12; color: Theme.accentName === accentButton.modelData ? Theme.text : Theme.secondary }
                                    }
                                    onClicked: Theme.accentName = modelData
                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                }
                            }
                        }
                    }
                }

                Flickable {
                    contentWidth: width
                    contentHeight: settingsEditorColumn.height + 44
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ThinScrollBar { }
                    Column {
                        id: settingsEditorColumn
                        x: 30
                        y: 22
                        width: parent.width - 60
                        spacing: 0
                        Text { text: "Editor"; font.family: Theme.uiFont; font.pixelSize: 18; font.weight: Font.DemiBold; color: Theme.text }
                        Text { text: "Give your words a little room to breathe."; font.family: Theme.uiFont; font.pixelSize: 11; color: Theme.secondary; topPadding: 8; bottomPadding: 18 }
                        Item {
                            width: parent.width
                            height: 25
                            Text { text: "Font size"; font.family: Theme.uiFont; font.pixelSize: 12; color: Theme.text }
                            Text { anchors.right: parent.right; text: Math.round(Theme.editorFontSize) + " px"; font.family: Theme.uiFont; font.pixelSize: 12; color: Theme.secondary }
                        }
                        SettingsSlider { width: parent.width; objectName: "fontSizeSlider"; from: 12; to: 22; stepSize: 1; value: Theme.editorFontSize; Accessible.name: "Editor font size"; onMoved: Theme.editorFontSize = value }
                        Item { width: 1; height: 10 }
                        Item {
                            width: parent.width
                            height: 25
                            Text { text: "Line height"; font.family: Theme.uiFont; font.pixelSize: 12; color: Theme.text }
                            Text { anchors.right: parent.right; text: Theme.lineHeight.toFixed(2); font.family: Theme.uiFont; font.pixelSize: 12; color: Theme.secondary }
                        }
                        SettingsSlider { width: parent.width; objectName: "lineHeightSlider"; from: 1.3; to: 2.0; stepSize: 0.05; value: Theme.lineHeight; Accessible.name: "Editor line height"; onMoved: Theme.lineHeight = Math.round(value * 100) / 100 }
                        Item { width: 1; height: 8 }
                        SettingsToggle { width: parent.width; height: 62; title: "Show line width guide"; detail: "A subtle guide for a comfortable reading measure."; controlName: "showGuideToggle"; checked: Theme.showGuide; onToggled: function(state) { Theme.showGuide = state } }
                        Rectangle {
                            width: parent.width
                            height: Math.max(120, editorPreviewText.implicitHeight + 50)
                            radius: 6
                            color: Theme.bg
                            border.color: Theme.border
                            Text { x: 16; y: 12; text: "PREVIEW"; font.family: Theme.uiFont; font.pixelSize: 9; font.letterSpacing: 1; color: Theme.muted }
                            Text { id: editorPreviewText; x: 16; y: 38; width: parent.width - 32; text: "A little room to think.\nMake space for the ideas that matter."; font.family: Theme.serifFont; font.pixelSize: Theme.editorFontSize; lineHeight: Theme.lineHeight; lineHeightMode: Text.ProportionalHeight; color: Theme.text; elide: Text.ElideRight }
                            Rectangle { x: parent.width - 30; y: 32; height: parent.height - 44; width: 1; color: Theme.border; visible: Theme.showGuide }
                        }
                    }
                }

                Flickable {
                    contentWidth: width
                    contentHeight: settingsBehaviorColumn.height + 47
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ThinScrollBar { }
                    Column {
                        id: settingsBehaviorColumn
                        x: 30
                        y: 25
                        width: parent.width - 60
                        spacing: 0
                        Text { text: "Behavior"; font.family: Theme.uiFont; font.pixelSize: 18; font.weight: Font.DemiBold; color: Theme.text }
                        Text { text: "Small preferences that make a workspace yours."; font.family: Theme.uiFont; font.pixelSize: 11; color: Theme.secondary; topPadding: 8; bottomPadding: 15 }
                        SettingsToggle { width: parent.width; title: "Autosave"; detail: "Keep your notes saved as you write."; checked: Theme.autosave; controlName: "autosaveToggle"; onToggled: function(state) { Theme.autosave = state } }
                        Rectangle { width: parent.width; height: 1; color: Theme.border }
                        SettingsToggle { width: parent.width; title: "Open last workspace"; detail: "Pick up where you left off when Aurora opens."; checked: Theme.openLastWorkspace; controlName: "openLastWorkspaceToggle"; onToggled: function(state) { Theme.openLastWorkspace = state } }
                        Rectangle { width: parent.width; height: 1; color: Theme.border }
                        SettingsToggle { width: parent.width; title: "Confirm before archive"; detail: "Ask before moving a note into the archive."; checked: Theme.confirmArchive; controlName: "confirmArchiveToggle"; onToggled: function(state) { Theme.confirmArchive = state } }
                        Text { width: parent.width; text: "Archived notes are always available in your sidebar."; font.family: Theme.uiFont; font.pixelSize: 11; color: Theme.muted; wrapMode: Text.WordWrap; topPadding: 22 }
                    }
                }
            }
        }
        Item {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 59
            Rectangle { width: parent.width; height: 1; color: Theme.border }
            Icon { x: 26; anchors.verticalCenter: parent.verticalCenter; name: "check"; size: 14; color: Theme.muted }
            Text { x: 48; anchors.verticalCenter: parent.verticalCenter; text: "Preferences are saved automatically"; font.family: Theme.uiFont; font.pixelSize: 11; color: Theme.muted }
            AuroraButton { anchors.right: parent.right; anchors.rightMargin: 23; anchors.verticalCenter: parent.verticalCenter; width: 77; height: 32; text: "Done"; quiet: false; tooltip: "Close settings"; onClicked: settings.close() }
        }
    }
}
