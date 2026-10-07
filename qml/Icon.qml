import QtQuick

Image {
    id: icon
    property string name: "document"
    property int size: 18
    property color color: Theme.secondary
    width: size; height: size
    sourceSize.width: size * 2; sourceSize.height: size * 2
    fillMode: Image.PreserveAspectFit
    smooth: true
    readonly property var paths: ({
        "aurora": '<path d="M3 19 10 4h4l7 15M6 13h12M8 19l4-8 4 8"/>',
        "all": '<rect x="4" y="3" width="16" height="18" rx="2"/><path d="M8 7h8M8 11h8M8 15h5"/>',
        "document": '<path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9zM14 3v6h6M8 13h8M8 17h5"/>',
        "star": '<path d="m12 3 2.8 5.8 6.4.9-4.6 4.5 1.1 6.4-5.7-3-5.7 3 1.1-6.4L2.8 9.7l6.4-.9z"/>',
        "clock": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
        "archive": '<rect x="3" y="3" width="18" height="4" rx="1"/><path d="M5 7v13h14V7M9 11h6"/>',
        "folder": '<path d="M3 7V5h6l2 2h10v12H3z"/>',
        "personal": '<path d="M3 11 12 3l9 8M5 10v11h14V10M10 21v-7h4v7"/>',
        "design": '<rect x="4" y="4" width="16" height="16" rx="2"/><path d="M4 9h16M9 9v11"/>',
        "research": '<path d="M9 3h6M10 3v6l-6 10q-1 2 2 2h12q3 0 2-2L14 9V3M7 15h10"/>',
        "idea": '<path d="M9 18h6M9 21h6M8 15a7 7 0 1 1 8 0l-1 3H9z"/>',
        "bulb": '<path d="M9 18h6M9 21h6M8 15a7 7 0 1 1 8 0l-1 3H9z"/>',
        "plus": '<path d="M12 5v14M5 12h14"/>',
        "search": '<circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 4 4"/>',
        "filter": '<path d="M4 6h16M7 12h10M10 18h4"/>',
        "sort": '<path d="M8 4v16m-3-3 3 3 3-3M14 6h6M14 11h4M14 16h2"/>',
        "settings": '<path d="m9 3-1 3-3 1-2 3 2 2-1 3 3 2 3-1 2 2 3-2 1-3 3-1 2-3-2-2 1-3-3-2-3 1z"/><circle cx="12" cy="12" r="3"/>',
        "chevronDown": '<path d="m7 10 5 5 5-5"/>',
        "chevron-down": '<path d="m7 10 5 5 5-5"/>',
        "chevronRight": '<path d="m10 7 5 5-5 5"/>',
        "arrowRight": '<path d="M4 12h16m-6-6 6 6-6 6"/>',
        "more": '<circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/>',
        "close": '<path d="m6 6 12 12M6 18 18 6"/>',
        "x": '<path d="m6 6 12 12M6 18 18 6"/>',
        "sidebar": '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M9 4v16"/>',
        "panel": '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M9 4v16"/>',
        "list": '<path d="M8 6h12M8 12h12M8 18h12M4 6h.1M4 12h.1M4 18h.1"/>',
        "share": '<path d="M12 15V3m-4 4 4-4 4 4M5 12v8h14v-8"/>',
        "bold": '<path d="M7 4h6a4 4 0 0 1 0 8H7V4m0 8h7a4 4 0 0 1 0 8H7v-8"/>',
        "italic": '<path d="M10 4h8M6 20h8M14 4 10 20"/>',
        "heading": '<path d="M5 4v16M17 4v16M5 12h12"/>',
        "quote": '<path d="M4 6h6v7H5q-1 4 4 5M14 6h6v7h-5q-1 4 4 5"/>',
        "bullets": '<path d="M9 6h11M9 12h11M9 18h11"/><circle cx="4" cy="6" r=".8"/><circle cx="4" cy="12" r=".8"/><circle cx="4" cy="18" r=".8"/>',
        "numbers": '<path d="M10 6h10M10 12h10M10 18h10M3 4h2v5M3 12q3-3 3 0l-3 4h3M3 19h3M5 17v4"/>',
        "code": '<path d="m8 6-6 6 6 6M16 6l6 6-6 6M14 3 10 21"/>',
        "link": '<path d="m10 14 4-4M8 16l-1 1a4 4 0 0 1-6-6l4-4a4 4 0 0 1 6 0M16 8l1-1a4 4 0 0 1 6 6l-4 4a4 4 0 0 1-6 0" transform="translate(1 0) scale(.9)"/>',
        "highlight": '<path d="m8 14 7-10 5 4-7 10zM8 14l-3 5h7M4 22h16"/>',
        "check": '<path d="m5 12 4 4L19 6"/>',
        "sun": '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M5 5l1 1M18 18l1 1M5 19l1-1M18 6l1-1"/>',
        "moon": '<path d="M20 14A9 9 0 0 1 10 3a9 9 0 1 0 10 11z"/>',
        "system": '<rect x="3" y="4" width="18" height="13" rx="2"/><path d="M8 21h8M12 17v4"/>',
        "command": '<path d="M8 8h8v8H8zm0 0H5a3 3 0 1 1 3-3zm8 0V5a3 3 0 1 1 3 3zm0 8h3a3 3 0 1 1-3 3zm-8 0v3a3 3 0 1 1-3-3z"/>',
        "copy": '<rect x="8" y="8" width="12" height="13" rx="2"/><path d="M15 8V3H3v13h5"/>',
        "focus": '<path d="M3 9V3h6M15 3h6v6M21 15v6h-6M9 21H3v-6"/>',
        "minimize": '<path d="M5 12h14"/>',
        "maximize": '<rect x="5" y="5" width="14" height="14" rx="1"/>',
        "restore": '<path d="M9 6V3h12v12h-3"/><rect x="3" y="8" width="14" height="13" rx="1"/>',
        "download": '<path d="M12 3v12m-4-4 4 4 4-4M4 16v5h16v-5"/>'
    })
    source: "data:image/svg+xml," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="'+color+'" stroke-width="1.55" stroke-linecap="round" stroke-linejoin="round">'+(paths[name] || paths.document)+'</svg>')
}
