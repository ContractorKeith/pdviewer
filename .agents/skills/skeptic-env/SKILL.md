---
name: skeptic-env
description: "How a skeptical reviewer builds, runs, seeds and attacks pdviewer. Read by the skeptic-review skill; not a workflow on its own."
---

# skeptic-env — pdviewer

A sandboxed macOS 15+ PDF viewer (Swift 6, SwiftUI `DocumentGroup(viewing:)`,
PDFKit, no dependencies). v1 is done when you can open a PDF, page through it,
zoom, search, use outline/thumbnails, and it remembers where you left off.

## Stack and commands

```bash
brew install xcodegen swiftlint     # once
make gen                            # regenerate pdviewer.xcodeproj from project.yml
make build                          # Debug build into build/
make test                           # unit tests (Swift Testing)
make uitest                         # one XCUITest smoke run; screenshots in build/shots
swiftlint lint --strict --quiet     # lint exactly as CI runs it (make lint is not --strict)
make run PDF=/path/to/file.pdf      # build and open the dev app with a file
scripts/release.sh 0.0.0-qa         # unsigned Release archive + DMG in dist/ (no SIGN_IDENTITY)
```

Fixtures: tests build PDFs in memory (`TestPDF.make()`, `TextPDF.make()`). For
manual runs, generate scratch PDFs under `/tmp/pdviewer-qa/` (e.g. with
`cupsfilter`, `textutil` + `cupsfilter`, or a small Swift/PDFKit script): a
1000-page text PDF, a huge page size (36x48 in), an image-only page, an
encrypted PDF (`qpdf --encrypt` if installed), a deep outline.

Scratch data: the app stores reading positions and prefs in its sandbox
container (`~/Library/Containers/com.contractorkeith.pdviewer/`). Before
seeding or corrupting it, copy it to `/tmp/pdviewer-qa/container-backup` and
restore it afterwards. Note in the report what you changed.

## Platforms

| Platform | Ships | Review on | Notes |
|---|---|---|---|
| Linux | no | — | |
| macOS | yes | Mac Studio | Air only if a check needs this user's TCC grants |
| Windows | no | — | |

## What to attack

- **Input fields**: toolbar page field and Go to Page sheet (`ReaderToolbar`,
  `GoToPageSheet`, `ReaderController`): Int.min/Int.max, 0, negative, huge
  strings, unicode digits, whitespace, paste. Zoom limits at both ends.
- **Find** (`SearchController`, `FindBar`, `FindCommands`): rapid typing,
  close/reopen (⌘F, Done, Escape, Hide Find Bar), next/prev with zero results,
  search while a previous scan runs, changing documents mid-scan, empty and
  very long queries, a 1000-page document.
- **Navigation** (`NavigationHistory`, outline, thumbnails): back/forward at
  ends, outline entries with no destination, deep outlines, first/last page.
- **Reading position** (`ReadingPositionStore`): reopen restores page and zoom;
  file moved, replaced, shrunk to fewer pages, deleted; corrupt or wrong-type
  stored data; many files (is there a cap or prune?).
- **Document lifecycle** (`PDFFileDocument`, `PDFKitView`): non-PDF renamed
  `.pdf`, zero-byte file, encrypted PDF, file changed on disk while open,
  multiple windows and tabs, window restoration on relaunch, "— Locked"
  title, Save on a read-only viewer.
- **UI**: light and dark mode, invert toggle, smallest and largest window,
  keyboard-only use of every menu shortcut in `AGENTS.md`, VoiceOver labels.
- **Packaging**: run `scripts/release.sh` unsigned, mount the DMG, launch the
  app *from the DMG copy*, check Info.plist document types, version, icon,
  entitlements (`codesign -d --entitlements - <app>`).
- **Docs**: every command in `README.md`, `CONTRIBUTING.md` and `AGENTS.md`
  as typed, from a fresh shell.

## Traps

- `pdviewer.xcodeproj`, `Info.plist` and the entitlements file are generated
  from `project.yml` and gitignored. Edit `project.yml`, never those.
- `PDFFileDocument` declares PDF writable on purpose: an empty writable set
  makes NSDocument show "— Locked". Save writes the original bytes back.
- Scale limits are set before `autoScales` on purpose (the reverse disables
  auto-fit on a zero-sized view; a regression test covers it).
- Reading positions are keyed by path; losing the position after a file move
  is documented, not a bug.
- `release.sh` without `SIGN_IDENTITY` ad-hoc signs and skips notarization by
  design. Signed/notarized distribution needs Keith's Developer ID; mark it
  not run.
- `screencapture` may be blocked; use `make uitest` attachments for visual
  evidence.
- The Mac Studio has only Command Line Tools (no Xcode) as of 2026-11-01, so
  `make build|test|uitest|run` and `release.sh` cannot run there. Either install
  Xcode on it first or run those checks on the Air. `swiftlint` there needs
  `TOOLCHAIN_DIR=/Library/Developer/CommandLineTools`.
- `-only-testing:` with Swift Testing needs suite names (or `name()`); a bare
  test name silently runs 0 tests and reports TEST SUCCEEDED.
- An uncaught ObjC exception in a unit test hangs the test host rather than
  failing; run `make test` under `timeout`.
- Xcode prints CoreSimulator version warnings on macOS tests; not a finding
  on their own.

## Earlier rounds

- 2026-10-31, `82f3603`, `worklog/reports/pdviewer-review-2026-10-31.md`:
  #2 Int.min in the toolbar page field trapped on subtraction (fixed, PR #4);
  #1 reopening Find kept the query but lost results (fixed, PR #3).
- 2026-11-01, `f3e8082`, `worklog/reports/pdviewer-review-2026-11-01.md`:
  stored displayMode outside 0...3 crashed on open; fit-width clamped at 25% on
  48-inch sheets; one bad store entry wiped all positions (fixed, round-2 PR).
