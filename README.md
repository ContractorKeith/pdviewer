# pdviewer

A fast, minimal PDF viewer for macOS. Open a file, read it, search it, close it, and
pick up where you left off next time. Nothing else.

Swift 6, SwiftUI, and Apple's PDFKit. No third-party code, no accounts, no network
access, no telemetry. Sandboxed. MIT licensed.

**Status:** v1 complete (0.1.0). Requires macOS 15 Sequoia or newer.

## Why it exists

Preview does a lot, and it has gotten slow and cluttered doing it. Opening a 200 MB
plan set or a 4,000-page manual means waiting, and once it's open you fight the
toolbar to get a clean reading view. Browser tabs are faster but forget where you were
the moment you close them.

pdviewer takes the opposite approach: one job, done quickly. A 209 MB, 4,234-page manual
opens and renders its first page in under three seconds on an M-series Mac. The window
is the page. Every control is one click or one keystroke away, and the app remembers
your page and zoom per file so reopening a document puts you back where you stopped.

## What it does

### Opening files

- Double-click a PDF in Finder, drag one onto the Dock icon or the window, use
  File > Open, or File > Open Recent.
- Each document gets its own window. Native macOS window tabbing works, so you can
  merge windows into tabs from the Window menu or by dragging.
- Encrypted PDFs prompt for the password through PDFKit's standard dialog.
- Launching the app with nothing open shows the Open panel.

### Reading

- **Display modes:** single page, single page continuous (default), two pages, two
  pages continuous. Pick from the toolbar menu or View > Display Mode.
- **Zoom:** fit width (default), fit page, actual size, and presets from 50% to 400%.
  Pinch to zoom on a trackpad, or ⌘+ / ⌘- in steps of 25%. The toolbar shows the live
  percentage and whether fit-width is on.
- **Paging:** arrow keys, space, Page Up/Down, Home/End, and the scroll wheel all work
  as you'd expect in each mode. ⌘← and ⌘→ step pages; ⌘↑ and ⌘↓ jump to first and last.
- **Page field:** the toolbar shows "n of N". Click the number, type a page, press
  Return.
- The window subtitle always shows the current page and total.

### Navigating

- **Sidebar** (⌃⌘S to show or hide) with two views:
  - **Thumbnails** of every page, synced with the main view in both directions.
  - **Outline**, the document's table of contents, as a collapsible tree. The section
    you're reading is shown in bold. Documents without an outline say so.
- **Go to Page** (⌥⌘G) opens a small sheet; type a number and press Return.
- **Back and Forward** (⌘[ and ⌘]) retrace jumps you made through the outline, Go to
  Page, or first/last page. Ordinary scrolling isn't recorded, so history stays
  meaningful.

### Searching

- ⌘F opens a find bar above the page. Results appear as you type, after a short pause.
- Every match is highlighted in yellow; the current one in orange, scrolled into view.
- The bar shows "3 of 42". Return or ⌘G goes to the next match, Shift-Return or ⇧⌘G to
  the previous. Both wrap around.
- ⌘E searches for whatever text you have selected on the page.
- On very large documents, results stream in while the scan runs, and typing a new
  query cancels the old scan immediately.
- Escape or Done closes the bar and clears the highlights.

### Remembering where you were

- When you leave a document, pdviewer stores the page, zoom level, and display mode for
  that file. Opening the same file later restores all three.
- Positions are keyed by the file's path and size. If the file is replaced with a
  different one at the same path, the old position is ignored. Moved or renamed files
  start fresh.
- The store is a single JSON file inside the app's sandbox container, capped at 500
  entries with the oldest dropped first. Writes are debounced so scrolling never touches
  the disk more than once a second.
- Window restoration on relaunch is handled by macOS. It depends on System Settings >
  Desktop & Dock > "Close windows when quitting an application": with that on (the
  default), a clean quit closes everything and the next launch shows the Open panel.

### Appearance, printing, sharing

- Follows the system light or dark appearance.
- **Invert Colors** (⌥⌘I, View menu) turns white pages dark for night reading. It inverts
  and then rotates hue by 180°, so colored content keeps roughly its original colors.
  The setting persists across launches.
- **Print** (⌘P) uses the standard macOS print panel with pages auto-rotated to fit.
- **Share** from the toolbar button or File > Share sends the file to Mail, Messages,
  AirDrop, or any other share destination.
- File > Save, Duplicate, Rename, and Move To work as they do in any macOS document
  app. Since pdviewer never edits a PDF, Save writes the original bytes back unchanged.

### Keyboard reference

| Action | Shortcut |
|---|---|
| Open / Close | ⌘O / ⌘W |
| Zoom in / out / actual size | ⌘+ / ⌘- / ⌘0 |
| Fit width / fit page | ⌘9 / ⇧⌘9 |
| Next / previous page | ⌘→ / ⌘← |
| First / last page | ⌘↑ / ⌘↓ |
| Go to page | ⌥⌘G |
| Back / forward | ⌘[ / ⌘] |
| Find / next / previous | ⌘F / ⌘G / ⇧⌘G |
| Use selection for find | ⌘E |
| Show or hide sidebar | ⌃⌘S |
| Invert colors | ⌥⌘I |
| Print | ⌘P |

Every control has an accessibility label and the app is fully usable from the keyboard.

## How it works

The whole app is about two dozen Swift files.

- **Document.** `PDFFileDocument` is a read-only SwiftUI `FileDocument` wrapping a
  PDFKit `PDFDocument`. The app's scene is `DocumentGroup(viewing:)`, which gives Open,
  Open Recent, tabs, and window restoration through AppKit's `NSDocument` machinery
  without any custom AppKit code.
- **One seam.** `ReaderController` is the single object between the UI and PDFKit's
  `PDFView`. It mirrors the view's state (page, scale, display mode) into observable
  properties and exposes every action (paging, zoom, display mode, print). Views,
  toolbar, and menus talk only to the controller, never to `PDFView` directly. Two small
  sub-controllers hang off it: `SearchController` (find) and `NavigationHistory`
  (back/forward).
- **Rendering.** `PDFKitView` hosts `PDFView` through `NSViewRepresentable`. PDFKit
  draws the pages, handles scrolling, keyboard paging, pinch zoom, text selection, and
  password prompts. pdviewer configures it and stays out of the way. The thumbnail strip
  is PDFKit's `PDFThumbnailView`, which syncs itself with the main view.
- **Search.** Uses `PDFDocument.beginFindString`, which scans pages off the main thread
  and reports each match on the main thread. A pending-scan counter makes sure a
  cancelled scan's completion can't end the one that replaced it.
- **State.** `ReadingPositionStore` is the per-file memory, a `@MainActor` singleton
  backed by one JSON file. Preferences like Invert Colors live in `UserDefaults` via
  `@AppStorage`.
- **Menus and toolbar.** Each menu is its own `Commands` struct (`FileCommands`,
  `ViewCommands`, `GoCommands`, `FindCommands`) that reaches the focused window's
  controller through `FocusedValues`. The toolbar is one `ToolbarContent` struct.

The design decision and its trade-offs are written up in
[docs/features/document-architecture/DECISION.md](docs/features/document-architecture/DECISION.md).
The original plan and milestones are in [docs/PLAN.md](docs/PLAN.md).

## Privacy and security

- App Sandbox is on. The app can read only files you open, plus its own container.
- The only entitlements are user-selected read-only file access, app-scoped bookmarks,
  and printing.
- No network code exists in the app. Nothing is logged or sent anywhere.
- Hardened runtime is enabled; release builds are Developer ID signed and notarized.

## Install

Download the latest `pdviewer-x.y.z.dmg` from
[Releases](https://github.com/ContractorKeith/pdviewer/releases), open it, and drag
pdviewer to Applications. To make it the default PDF app, select any PDF in Finder,
press ⌘I, choose pdviewer under "Open with," and click "Change All."

## Build from source

```bash
brew install xcodegen          # generates the Xcode project from project.yml
git clone https://github.com/ContractorKeith/pdviewer.git
cd pdviewer
make build                     # Debug build into build/
make run PDF=path/to/file.pdf  # build and open a file
```

Or `make gen && open pdviewer.xcodeproj` to work in Xcode. Requires Xcode 16 or newer.
The `.xcodeproj`, `Info.plist`, and entitlements are generated from `project.yml` and
not checked in; edit the YAML and regenerate.

### Tests

```bash
make test     # 35 unit tests (Swift Testing): document loading, controller logic,
              # outline flattening, history, search, reading-position store
make uitest   # one XCUITest smoke run: launches the app with a generated PDF,
              # checks title, outline, search, and invert, saves screenshots
make lint     # swiftlint
```

Unit tests build their PDFs in memory, so there are no fixture files in the repo.

### Release

```bash
SIGN_IDENTITY="Developer ID Application: Name (TEAMID)" \
NOTARY_PROFILE=pdviewer-notary \
scripts/release.sh 0.1.0
```

Archives a Release build, signs it, packages a DMG with `hdiutil`, submits it to Apple
for notarization, staples the ticket, and writes a SHA-256 next to it. Without
`SIGN_IDENTITY` it produces an ad-hoc signed DMG for local testing. The version number
and git commit count are stamped into the bundle.

## Repository layout

```
pdviewer/
  App/          app entry, one Commands file per menu
  Document/     PDFFileDocument, OutlineItem
  State/        ReaderController, SearchController, NavigationHistory,
                ReadingPositionStore, Preferences
  Views/        ReaderView, PDFKitView, ReaderToolbar, SidebarView,
                ThumbnailsView, OutlineView, FindBar, GoToPageSheet
  Resources/    asset catalog (icon, accent color)
pdviewerTests/  unit tests and in-memory PDF fixtures
pdviewerUITests/ smoke test
scripts/        make-icon.swift, release.sh
docs/           plan, decision records, feature notes
```

## Not in scope

pdviewer is a viewer. It does not annotate, fill forms, sign, redact, reorder pages, or
merge files, and it has no cloud, sync, or plugin system. Some of those may come later
(measurement for scaled drawings, split view, page reordering are on the maybe list in
`docs/PLAN.md`), but each would have to earn its place without slowing the app down.

## Contributing

Bug reports and small fixes are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first,
and open an issue before starting anything bigger than a bug fix so we can agree on
scope. When reporting a rendering or performance problem, include the macOS version and
a description of the PDF (page count, size, scanned or text, encrypted, outline), or the
file itself if you can share it.

## License

MIT. See [LICENSE](LICENSE).
