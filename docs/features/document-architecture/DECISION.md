# Decision: SwiftUI `DocumentGroup(viewing:)` over an `NSDocument` subclass

Date: 2026-10-31. Status: decided for v1.

## Choice

The app is a SwiftUI `App` with `DocumentGroup(viewing: PDFFileDocument.self)`.
`PDFFileDocument` is a `FileDocument` struct holding a `PDFDocument`. `PDFView` is
wrapped in `PDFKitView` (`NSViewRepresentable`) and driven through `ReaderController`.

## Why

- Open, Open Recent, native window tabs, and window restoration come from NSDocument
  under the hood with zero AppKit glue.
- Menus (`Commands`) and toolbars are plain SwiftUI. Window-scoped state reaches menus via
  `FocusedValues.readerController`.
- Read-only by intent: `viewing:`, no autosave. `writableContentTypes` is `[.pdf]`
  because an empty set makes NSDocument title windows "— Locked"; File > Save exists
  and writes the original bytes back (the file's modified time changes).
- Far less code for the same native behavior. Less to review, less to break.

## Costs accepted

- `FileDocument` hands us `Data`, not a URL, so the whole file is read into memory before
  `PDFDocument(data:)`. Fine for typical files; test against 200 MB+ plan sets in
  milestone 2 and revisit if it hurts. `config.fileURL` is still available to the view
  for reading-position bookmarks.
- `PDFDocument` is not `Sendable`; `PDFFileDocument` is `@unchecked Sendable` and only
  touched on the main actor.
- v2 page editing (reorder/delete) means switching to `ReferenceFileDocument` and
  `DocumentGroup(newDocument:)`/`editing:`. The reader seam (`ReaderController`) does
  not care which, so this is contained to `PDFFileDocument` and the `App` body.

## Fallback

If `DocumentGroup` blocks something concrete (likely candidates: custom window
restoration data, per-window toolbar customization), switch to an `NSDocument` subclass
whose `makeWindowControllers()` hosts `ReaderView` in an `NSHostingController`. Only
`App/` and `Document/` change.

## Tooling

- `project.yml` (XcodeGen) is the source of truth. The `.xcodeproj`, `Info.plist`, and
  entitlements are generated and gitignored. `make gen` regenerates.
- Swift 6 language mode, strict concurrency. `ReaderController` is `@MainActor`.
