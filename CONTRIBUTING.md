# Contributing to pdviewer

Thanks for helping. pdviewer is a small, focused macOS PDF viewer. Keep it that way.

## Setup

```bash
brew install xcodegen swiftlint
git clone https://github.com/ContractorKeith/pdviewer.git
cd pdviewer
make gen      # generates pdviewer.xcodeproj from project.yml
open pdviewer.xcodeproj
```

Requires Xcode 16 or newer and macOS 15 or newer. The `.xcodeproj`, `Info.plist`, and
entitlements are generated; edit `project.yml` instead and re-run `make gen`.

## Before you open a PR

```bash
make build
make test
make lint
```

All three must pass. CI runs the same.

## Ground rules

- **Scope.** Read `docs/PLAN.md` first. v1 is a viewer: open, read, navigate, search,
  remember. Annotation, editing, cloud, and telemetry are out. Open an issue before
  starting anything larger than a bug fix.
- **No new dependencies** without a reason PDFKit or the SDK can't cover.
- **Architecture.** Views talk to `ReaderController`, never to `PDFView` directly. One
  feature per file. See `AGENTS.md` for the layout.
- **Swift 6, strict concurrency.** UI code is `@MainActor`.
- **Tests** for anything that isn't a view: Swift Testing in `pdviewerTests/`.
- **Commits**: `<type>: <description>` with type one of feat, fix, refactor, docs, test,
  chore, perf, ci.
- **Accessibility.** Every control gets a label. Keyboard-only use must work.

## Reporting bugs

Include macOS version, the app version (pdviewer > About), and if possible a PDF that
reproduces the problem (or a description of its shape: page count, size, scanned or
text, encrypted, outline).

## License

By contributing you agree your work is released under the MIT License.
