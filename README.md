# Aurora Notes

A native desktop notes app built with Qt 6, QML and a small C++ document backend. Aurora opens with seeded notes and uses a warm editorial palette, restrained motion and a readable text measure.

## Build and run

Install Qt 6.5 or later with **Core**, **Gui**, **Quick**, **QuickControls2** and **Svg**, plus the Qt Quick Controls, Layouts and Dialogs QML modules. You also need a C++17 compiler, CMake 3.21 or later and Ninja. Qt Test is optional for the test target.

From this directory:

The supplied Linux build can be launched with `./run.sh`. The launcher builds from source if a binary is not present.

The included executable is for Linux x86_64, built with Qt 6.11.2, and needs the matching Qt libraries and QML modules. Build from source for another platform or Qt version.

```sh
cmake -S . -B build -G Ninja
cmake --build build
./build/aurora-notes
```

If Qt is installed outside your system paths, set `CMAKE_PREFIX_PATH` to the Qt installation when configuring. Noto Sans, Noto Serif and JetBrains Mono are bundled for consistent typography. Their SIL Open Font License and copyright notices are in `fonts/OFL.txt`.

## Working with notes

- Browse All Notes, Favorites, Recent and Archive, or the Personal, Design, Research and Ideas workspaces.
- Search titles and note content, filter favorites, and sort by recent edits or title.
- Create notes, edit their titles and bodies, duplicate them, move them between workspaces, and archive or restore them. Right-click a note to open its actions.
- Format text with bold, italic, headings, quotes, lists, inline code and links. Selecting text reveals a floating toolbar with bold, italic, highlight and link actions.
- Copy a note as Markdown or export it through the Share menu.
- Collapse and restore navigation or the note list, drag the note-list divider, and use editor focus mode. The sidebar reduces to icons below 1050 px; the note list automatically hides below 820 px. Restoring panels at smaller widths opens temporary panels over the editor to preserve its reading space.
- Use the command palette to create, search, toggle panels, switch themes, open settings or archive a note.
- Choose Dark, Light or System appearance, Comfortable or Compact density, and Warm, Blue or Green accents. Editor preferences include font size, line height and a reading-width guide. Behavior preferences include autosave, reopening the last workspace and archive confirmation.

Notes are saved locally in `notes.json` under Qt's platform-specific `QStandardPaths::AppDataLocation` for Aurora Notes. Appearance and behavior preferences use Qt settings. When autosave is disabled, use the save shortcut to write changes.

## Keyboard shortcuts

Use **Command** in place of **Ctrl** on macOS.

| Shortcut | Action |
| --- | --- |
| Ctrl + K | Open command palette |
| Ctrl + N | Create a note |
| Ctrl + F | Focus note search |
| Ctrl + S | Save notes |
| Ctrl + Shift + \\ | Toggle sidebar |
| Ctrl + , | Open settings |
| Ctrl + B | Bold in editor |
| Ctrl + I | Italic in editor |
| Ctrl + L | Add or edit a link in editor |
| ↑ / ↓, Enter | Navigate and run a palette command |
| Escape | Close a popup or command palette |

Tab moves between controls. Search results and note selection also support keyboard navigation.

## Preview options

```sh
./build/aurora-notes --demo --size 1440x900
./build/aurora-notes --demo --light --settings --snapshot settings-light.png
```

| Option | Purpose |
| --- | --- |
| `--demo` | Start with seeded notes; do not read or write saved notes. |
| `--size WIDTHxHEIGHT` | Set the initial window size. Default: `1440x900`. |
| `--light` | Start in the light theme. |
| `--settings` | Open settings at launch. |
| `--palette` | Open the command palette at launch. |
| `--snapshot PATH` | Save a rendered PNG after startup and exit. |
| `--help` | Show the available command-line options. |

Demo mode keeps note changes in memory. Preference changes still use Qt settings.

## Source layout

`qml/` contains the shell, sidebar, note list, editor, theme and reusable controls. `src/NotesStore` owns note data and persistence; `src/DocumentHandler` applies rich-text formatting to the native Qt text document.

No web view or external UI framework is used.

## Verification

With the Qt Test module installed:

```sh
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build
ctest --test-dir build --output-on-failure
```

The backend suite checks search, creation while filtered, edits, sorting, duplication, favorites, workspace moves, archiving/restoring, and Markdown export. The native interface suite exercises the benchmark flow using Qt keyboard and pointer events, including text selection, formatting, settings, theme changes, resizing, and the archive toast. Tests render offscreen and use isolated preferences.

Both suites passed with Qt 6.11.2. The save/reopen cycle was verified, and native renders were inspected at 1440×900, 900×650, 2560×1080, and 2× display scaling. Dark, light, and settings previews are included in `previews/`.

## Backup artifacts

This repository preserves the complete Aurora Notes project, bundled fonts and their license, the Linux executable in `bin/`, and six rendered previews. `artifacts/Aurora-Notes.zip` contains the complete original deliverable. The original specification and final test log are in `docs/`. `docs/backup-manifest.json` records SHA-256 checksums and sizes for the backed-up files.
