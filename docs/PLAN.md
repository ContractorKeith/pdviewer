# pdviewer — v1 Plan

Status: draft, 2026-10-31. No code yet.

## Goal

A macOS PDF viewer that opens instantly, reads well, searches fast, and remembers where
you were. Nothing else. MIT licensed so anyone can fork it.

## Who it's for

Anyone on a Mac who opens a lot of PDFs and finds Preview slow or cluttered. Strictly
general-purpose: no domain-specific features in v1.

## Stack

- **Swift 6, SwiftUI** for the app shell, toolbar, sidebar, settings.
- **PDFKit** (`PDFView`, `PDFDocument`, `PDFOutline`, `PDFThumbnailView`) for rendering,
  search, outline, and thumbnails. Wrapped in `NSViewRepresentable`.
- **AppKit** only where SwiftUI is missing: menu bar commands, window restoration, open
  panel details.
- **Xcode project**, not a bare Swift package, because the app target needs an
  entitlements file, Info.plist document types, and an app icon.
- **No third-party dependencies.** PDFKit covers v1. Revisit only if a concrete limit
  shows up (e.g. rendering speed on 500-page plan sets).

Minimum target: macOS 15 (Sequoia). Keeps SwiftUI document APIs and `@Observable`
available without back-compat shims.

## Scope: v1

1. **Open** PDFs via Finder (double-click, drag to Dock), File > Open, drag onto window,
   and Open Recent. Register as a handler for `com.adobe.pdf`.
2. **Read**: continuous scroll and single-page modes, fit-width / fit-page / custom zoom,
   keyboard paging (arrows, space, Page Up/Down), pinch and ⌘+/⌘- zoom.
3. **Navigate**: sidebar with outline (bookmarks) and page thumbnails, go-to-page field,
   back/forward history within a document.
4. **Search**: ⌘F find bar, incremental highlights, result count, next/previous.
5. **Remember**: per-file last page and zoom, restored on reopen. Store by security-scoped
   bookmark so it survives sandboxing. Restore open windows on relaunch.
6. **Tabs**: one window per document by default, with native macOS tabbing supported.
7. **Dark mode**: respect system appearance; optional "invert page colors" toggle for
   night reading.
8. **Print** and **Share** via the standard macOS sheets.

## Out of scope for v1

- Annotation, form filling, signing, redaction, page reordering, merge/split.
- Cloud storage integration, sync, accounts, analytics, update checks.
- Plugin system or scripting.
- App Store distribution. GitHub Releases only: Developer ID-signed, notarized DMG.
  Keep the app sandboxed anyway; it costs little and keeps the App Store door open.

## Architecture

```
pdviewer/
  App/            pdviewerApp.swift, AppDelegate (menus, reopen, document handling)
  Document/       PDFDocumentModel (wraps PDFDocument, exposes outline, page count, search)
  Views/          ReaderView, PDFKitView (NSViewRepresentable), SidebarView,
                  OutlineView, ThumbnailsView, FindBar, Toolbar
  State/          ReadingPosition store (bookmark -> page/zoom), RecentFiles
  Resources/      Assets, Info.plist document types, entitlements
pdviewerTests/    ReadingPosition round-trip, search result mapping, outline flattening
docs/
  PLAN.md         this file
  features/       one folder per larger feature as they appear (per projects.POLICY.md)
```

Use SwiftUI's `DocumentGroup` with a `ReferenceFileDocument` conforming wrapper if it
handles tabs, recents, and restoration cleanly. If it fights us (likely around window
restoration and read-only documents), fall back to an `NSDocument` subclass behind a
SwiftUI content view. Decide this in milestone 1 with a spike, not on paper.

## Milestones

| # | Milestone | Done when |
|---|-----------|-----------|
| 1 | Skeleton | Xcode project, app opens a PDF from Finder and renders it in `PDFView`. Document-architecture decision made and recorded. |
| 2 | Reading | Zoom modes, display modes, keyboard paging, toolbar. Feels right on a 300-page file. |
| 3 | Navigate | Sidebar with outline + thumbnails, go-to-page, history. |
| 4 | Search | Find bar with highlights and next/prev. |
| 5 | Remember | Reading position persisted and restored; recents; window restoration. |
| 6 | Polish | Dark mode, invert toggle, print/share, app icon, menu audit, accessibility pass (VoiceOver labels, keyboard-only use). |
| 7 | Ship | Developer ID-signed, notarized DMG (local signing first, GitHub Actions later), `CONTRIBUTING.md`, release notes, 0.1.0 tag. |

Each milestone is a PR. Milestone 1 gets a short spike doc under `docs/features/document-architecture/`.

## Testing

- Unit tests for everything not tied to a view: reading-position store, search result
  mapping, outline flattening, recents pruning.
- Manual checklist per milestone with a handful of real PDFs: a scanned (image-only)
  PDF, a plan set with huge page sizes, a 1000-page text PDF, an encrypted PDF, a
  PDF with a deep outline.
- XCUITest only for the open-file-and-render smoke path. UI tests are slow and brittle;
  keep them to one.

## Risks and open questions

- **PDFKit performance** on very large page sizes (architectural sheets at 36×48") is
  unknown. Test in milestone 1 with a real plan set before committing further.
- **`DocumentGroup` vs `NSDocument`**: SwiftUI document apps have rough edges on macOS
  (window restoration, read-only files). Spike it early.
- **Sandbox + recents**: security-scoped bookmarks are fiddly. Isolate in one type with
  tests.

## Later (v2 candidates, not committed)

Keep v1 architecture from blocking these, but build none of them yet.

- Measurement tool for scaled drawings (set scale, measure length/area).
- Split view: two pages or two documents side by side.
- Page organization: reorder, rotate, add, delete pages; merge and split files.
  This turns the app from read-only to read-write, so the document layer in
  milestone 1 should not assume documents never change.
- Annotations (highlight, note, freehand) via PDFKit's `PDFAnnotation`.
- Quick Look extension / Spotlight importer.
