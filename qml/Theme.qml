pragma Singleton
import QtQuick
import QtCore

QtObject {
    id: theme
    property string themeMode: "Dark"
    property string density: "Comfortable"
    property string accentName: "Warm"
    property int editorFontSize: 16
    property real lineHeight: 1.65
    property bool showGuide: false
    property bool autosave: true
    property bool openLastWorkspace: true
    property bool confirmArchive: false
    readonly property bool dark: themeMode === "Dark" || (themeMode === "System" && Qt.styleHints.colorScheme === Qt.Dark)
    readonly property bool compact: density === "Compact"
    property color bg: dark ? "#111315" : "#F3F1EC"
    property color sidebar: dark ? "#171A1D" : "#EBE8E1"
    property color surface: dark ? "#1D2125" : "#FFFFFF"
    property color hover: dark ? "#24292E" : "#E5E1D9"
    property color border: dark ? "#2D3339" : "#D9D5CE"
    property color text: dark ? "#F2F0EB" : "#1E2023"
    property color secondary: dark ? "#A5A29C" : "#6F6D68"
    property color muted: dark ? "#87837D" : "#77716A"
    property color accent: accentName === "Blue" ? (dark ? "#86B7CB" : "#3A738C") : accentName === "Green" ? (dark ? "#9BB49A" : "#537D55") : (dark ? "#DFA56B" : "#B86F3C")
    property color accentSoft: dark ? Qt.rgba(accent.r,accent.g,accent.b,0.10) : Qt.rgba(accent.r,accent.g,accent.b,0.12)
    readonly property string uiFont: "Noto Sans"
    readonly property string serifFont: "Noto Serif"
    readonly property string monoFont: "JetBrains Mono"
    readonly property int radius: 8
    readonly property int fast: 120
    readonly property int motion: 200
    readonly property int spacing: 8
    Behavior on bg { ColorAnimation { duration: 180 } }
    Behavior on sidebar { ColorAnimation { duration: 180 } }
    Behavior on surface { ColorAnimation { duration: 180 } }
    Behavior on hover { ColorAnimation { duration: 180 } }
    Behavior on border { ColorAnimation { duration: 180 } }
    Behavior on text { ColorAnimation { duration: 180 } }
    Behavior on secondary { ColorAnimation { duration: 180 } }
    Behavior on muted { ColorAnimation { duration: 180 } }
    Behavior on accent { ColorAnimation { duration: 180 } }
    property Settings preferences: Settings {
        category: "Appearance"
        property alias themeMode: theme.themeMode
        property alias density: theme.density
        property alias accentName: theme.accentName
        property alias editorFontSize: theme.editorFontSize
        property alias lineHeight: theme.lineHeight
        property alias showGuide: theme.showGuide
        property alias autosave: theme.autosave
        property alias openLastWorkspace: theme.openLastWorkspace
        property alias confirmArchive: theme.confirmArchive
    }
}
