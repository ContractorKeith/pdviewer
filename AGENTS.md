# pdviewer

A fast, minimal, open-source (MIT) macOS app for viewing PDFs. Swift 6, SwiftUI, and
Apple's PDFKit, no third-party dependencies. General-purpose: for anyone who wants a
lighter, quicker PDF viewer than Preview. v1 is done when you can open a PDF, page
through it, zoom, search text, see the outline/thumbnails, and it remembers where you
left off.

## Status
active — milestone 1 (skeleton) done 2026-10-31. Milestones 2–5 in progress.
Plan: `docs/PLAN.md`. Architecture decision: `docs/features/document-architecture/DECISION.md`.

## Commands
```bash
make gen     # regenerate pdviewer.xcodeproj from project.yml (xcodegen)
make build   # Debug build into build/
make test    # unit tests (Swift Testing)
make run PDF=path/to/file.pdf   # build and open the app with a file
make lint    # swiftlint
```
Requires Xcode 16+ and `brew install xcodegen`. The `.xcodeproj`, `Info.plist`, and
entitlements are generated and gitignored; edit `project.yml` instead.

## Architecture
```
pdviewer/
  App/        pdviewerApp (DocumentGroup(viewing:)), ReaderCommands composes
              ViewCommands / GoCommands / FindCommands (one file per menu).
  Document/   PDFFileDocument: read-only FileDocument wrapping PDFDocument.
  State/      ReaderController: the one seam between UI and PDFView. Mirrors
              PDFView state, exposes paging/zoom actions, owns the
              sub-controllers SearchController, NavigationHistory.
              ReadingPositionStore: per-file last position, app-wide.
  Views/      ReaderView (layout + wiring only), PDFKitView (NSViewRepresentable),
              SidebarView, ReaderToolbar, FindBar.
pdviewerTests/  Swift Testing. TestPDF.make() builds in-memory fixtures.
```
Views never touch `PDFView` directly; they go through `ReaderController`.

## Conventions & Gotchas
- macOS 15+ only. No iOS, iPadOS, or Catalyst targets.
- PDFKit does the rendering. Do not add a PDF library (PDFium, MuPDF, etc.) without a
  stated reason PDFKit cannot meet.
- Swift 6 language mode, strict concurrency. UI-facing classes are `@MainActor`.
  `NotificationCenter` block observers run on `.main`; wrap bodies in
  `MainActor.assumeIsolated`.
- `@Observable` classes: anything views should not observe gets `@ObservationIgnored`.
- Keep the app sandboxed. File access is user-opened files only, plus security-scoped
  bookmarks for remembering positions.
- Menu shortcuts: ⌘+/⌘-/⌘0 zoom, ⌘←/⌘→ page, ⌘[/⌘] back/forward, ⌘F find.
- Commit format `<type>: <description>`. Agent commits are authored by @ContractorKeith only.

## Out of Scope
- Editing, annotating, or signing PDFs (v1). Measure, split view, and page
  organize/add/delete are v2 candidates; see `docs/PLAN.md`.
- Domain-specific features. General-purpose viewer only.
- Cloud sync, accounts, or telemetry.
- App Store. Distribution is Developer ID-signed DMG on GitHub Releases.
- Windows, Linux, iOS builds.
