# pdviewer

A fast, minimal, open-source (MIT) macOS app for viewing PDFs. Built in Swift with
SwiftUI and Apple's PDFKit, no third-party dependencies. For anyone who wants a
lighter, quicker PDF viewer than Preview or a browser tab. "Done" for v1 means: open
a PDF, page through it, zoom, search text, see the outline/thumbnails, and remember
where you left off.

## Status
skeleton — last touched 2026-10-31. Plan written, no code yet. See `docs/PLAN.md`.

## Commands
```bash
# build (once the Xcode project exists):
xcodebuild -scheme pdviewer -configuration Debug build
# test:
xcodebuild -scheme pdviewer test
# open in Xcode:
open pdviewer.xcodeproj
```

## Architecture
- `docs/PLAN.md` — the v1 plan and milestones. Read it before any implementation work.
- `pdviewer/` — app source (SwiftUI app target). Created in milestone 1.
- `pdviewerTests/` — unit tests for non-UI logic.

## Conventions & Gotchas
- macOS only. No iOS, iPadOS, or Catalyst targets.
- PDFKit does the rendering. Do not add a PDF library (PDFium, MuPDF, etc.) without a
  stated reason PDFKit cannot meet.
- SwiftUI for the shell; wrap `PDFView` in `NSViewRepresentable` where SwiftUI falls short.
- Keep the app sandboxed. File access is user-opened files only (plus security-scoped
  bookmarks for recents).
- Commit format `<type>: <description>`. Agent commits are authored by @ContractorKeith only.

## Out of Scope
- Editing, annotating, or signing PDFs (v1).
- Cloud sync, accounts, or telemetry.
- Windows, Linux, iOS builds.
