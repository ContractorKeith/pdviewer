# Remember (milestone 5)

## Storage
- One JSON file: `Application Support/pdviewer/positions.json`. The app is sandboxed, so this
  lands in `~/Library/Containers/com.contractorkeith.pdviewer/Data/Library/Application Support/pdviewer/`.
- Plain `JSONEncoder` (pretty-printed, sorted keys, ISO-8601 dates). Missing or corrupt file starts empty (logged once).
- `save` updates memory immediately and writes to disk after a 1 s debounce. Also flushed on `willTerminate`.
- Capped at 500 entries; oldest by `updatedAt` is dropped.

## Key strategy
- Key is `url.standardizedFileURL.resolvingSymlinksInPath().path`.
- Not a security-scoped bookmark: bookmark data is opaque and not comparable, so it can't be a dictionary key.
  Moved or renamed files simply start fresh in v1.
- `fileSize` is stored to detect a replaced file; a mismatch skips restore. Size is read with
  `FileManager.attributesOfItem`, because `URL.resourceValues` caches and goes stale.
- Saves for a file that already has an entry are ignored until `restore` has run for it this session,
  so the freshly opened page-0 state cannot overwrite the saved position.

## What macOS gives us for free
- `DocumentGroup` provides File > Open Recent, and restores open windows on relaunch
  *unless* System Settings > Desktop & Dock > "Close windows when quitting an application"
  is on (the default). With that on, a clean quit forgets windows and the next launch shows
  the Open panel; a crash or kill still restores. Nothing for the app to do here.
- Verified: open plans.pdf, go to page 4, quit, relaunch. The window came back as
  "plans.pdf – Page 4 of 27" (a second window from an earlier session, manual.pdf, also came back).
  Window restoration reopens the file but not its page or zoom; `ReadingPositionStore.restore`
  covers that. The window title alone can't tell us which of the two put it on page 4.

## Limits
- Moved or renamed files lose their position. Files at the same path with a different size are treated as new.
- Restore retries once (250 ms) if the PDFView is not attached yet, then gives up.
- Multiple windows on the same file share one entry (last writer wins).
