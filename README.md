# pdviewer

A fast, minimal, open-source PDF viewer for macOS. Swift, SwiftUI, PDFKit. No dependencies,
no accounts, no telemetry.

**Status:** v1 feature-complete. First signed release coming. See [docs/PLAN.md](docs/PLAN.md).

## Why

Preview is heavy and slow to open large files. Browser tabs lose your place. pdviewer does
one thing: open a PDF instantly, let you read and search it, and remember where you were.
A 200 MB, 4,000-page manual opens in under three seconds.

## Features

- Open from Finder, drag and drop, File > Open, or Open Recent. Native window tabs.
- Continuous or single-page reading, one or two pages up. Fit width, fit page, presets,
  pinch and ⌘+/⌘- zoom.
- Sidebar with page thumbnails and the document outline. Go to page (⌥⌘G), back and
  forward (⌘[ / ⌘]).
- Find (⌘F) with live highlights and match count, streaming on huge documents.
- Remembers the page, zoom, and display mode per file and restores them on reopen.
  Reopens your windows on relaunch.
- Dark mode, plus Invert Colors (⌥⌘I) for night reading.
- Print and Share.
- Sandboxed. Reads only the files you open.

Requires macOS 15 (Sequoia) or newer.

## Install

Download the DMG from [Releases](https://github.com/ContractorKeith/pdviewer/releases),
drag pdviewer to Applications. Signed and notarized builds only.

## Build from source

```bash
brew install xcodegen
git clone https://github.com/ContractorKeith/pdviewer.git
cd pdviewer
make build          # or: make gen && open pdviewer.xcodeproj
make test           # unit tests
make uitest         # UI smoke test with screenshots
```

Xcode 16 or newer. The Xcode project is generated from `project.yml`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Scope is deliberately small; open an issue before
starting anything larger than a bug fix.

## License

MIT. See [LICENSE](LICENSE).
