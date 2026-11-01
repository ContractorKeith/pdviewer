# pdviewer

A fast, minimal, open-source (MIT) macOS app for viewing PDFs. Swift 6, SwiftUI, and
Apple's PDFKit, no third-party dependencies. General-purpose: for anyone who wants a
lighter, quicker PDF viewer than Preview. v1 is done when you can open a PDF, page
through it, zoom, search text, see the outline/thumbnails, and it remembers where you
left off.

## Status
active — v1 feature-complete 2026-10-31 (milestones 1–6). Milestone 7 (signed DMG
release) pending Keith's Developer ID signing. Plan: `docs/PLAN.md`. Architecture
decision: `docs/features/document-architecture/DECISION.md`.
Skeptic reviews: round 2 (2026-11-01, `f3e8082`) fixed #5, #6, #7; open weaknesses
(unused bookmarks entitlement, File > Save touches mtime, no branch protection) are in
`worklog/reports/pdviewer-review-2026-11-01.md`.

## Commands
```bash
make gen     # regenerate pdviewer.xcodeproj from project.yml (xcodegen)
make build   # Debug build into build/
make test    # unit tests (Swift Testing)
make uitest  # one XCUITest smoke run: opens a PDF, checks sidebar/search, saves screenshots
make run PDF=path/to/file.pdf   # build and open the app with a file
make lint    # swiftlint
```
Requires Xcode 16+ and `brew install xcodegen`. The `.xcodeproj`, `Info.plist`, and
entitlements are generated and gitignored; edit `project.yml` instead.

## Architecture
```
pdviewer/
  App/        pdviewerApp (DocumentGroup(viewing:)), ReaderCommands composes
              FileCommands / ViewCommands / GoCommands / FindCommands (one per menu).
  Document/   PDFFileDocument: read-only FileDocument wrapping PDFDocument.
  State/      ReaderController: the one seam between UI and PDFView. Mirrors
              PDFView state, exposes paging/zoom actions, owns the
              sub-controllers SearchController, NavigationHistory.
              ReadingPositionStore: per-file last position, app-wide.
              Preferences: UserDefaults keys for @AppStorage.
  Views/      ReaderView (layout + wiring only), PDFKitView (NSViewRepresentable),
              SidebarView, ReaderToolbar, FindBar.
pdviewerTests/  Swift Testing. TestPDF.make() (blank pages) and TextPDF.make()
                (searchable text) build in-memory fixtures.
pdviewerUITests/ One XCUITest smoke test; screenshots via `make uitest`.
scripts/        make-icon.swift (app icon), release.sh (sign, notarize, DMG).
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
- Keep the app sandboxed. File access is user-opened files only. Reading positions are
  keyed by resolved file path (no bookmarks), so a moved file starts fresh.
- Menu shortcuts: ⌘+/⌘-/⌘0 zoom, ⌘9 fit width, ⌘←/⌘→ page, ⌘↑/⌘↓ first/last,
  ⌥⌘G go to page, ⌘[/⌘] back/forward, ⌘F find, ⌘G/⇧⌘G next/previous, ⌥⌘I invert.
- Set PDFView scale limits before `autoScales`; the other order clamps a zero-sized
  view to the floor and turns auto-fit off (regression test covers it).
- Commit format `<type>: <description>`. Agent commits are authored by @ContractorKeith only.

## Out of Scope
- Editing, annotating, or signing PDFs (v1). Measure, split view, and page
  organize/add/delete are v2 candidates; see `docs/PLAN.md`.
- Domain-specific features. General-purpose viewer only.
- Cloud sync, accounts, or telemetry.
- App Store. Distribution is Developer ID-signed DMG on GitHub Releases.
- Windows, Linux, iOS builds.
