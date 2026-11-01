import AppKit
import OSLog
import PDFKit

/// Remembers where the user left off in each file (page, zoom, display mode)
/// and restores it on reopen. App-wide singleton; keyed by resolved file path.
/// Persisted as one JSON file; writes are debounced.
@MainActor
final class ReadingPositionStore {
    static let shared = ReadingPositionStore(fileURL: defaultURL)

    static var defaultURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appending(path: "pdviewer/positions.json")
    }

    private let fileURL: URL
    private let capacity: Int
    private let debounce: Duration
    private let log = Logger(subsystem: "com.contractorkeith.pdviewer", category: "ReadingPositionStore")

    private var positions: [String: ReadingPosition] = [:]
    private var isLoaded = false
    private var isDirty = false
    private var writeTask: Task<Void, Never>?
    /// Keys whose restore has started this session. Until then, saves must not
    /// overwrite an existing entry with the freshly opened (page 0) state.
    private var restoredKeys: Set<String> = []
    /// Keys waiting on a retried restore; saves are ignored meanwhile.
    private var restoring: Set<String> = []
    private var terminateObserver: NSObjectProtocol?

    /// Number of disk writes performed (for tests).
    private(set) var writeCount = 0

    init(fileURL: URL, capacity: Int = 500, debounce: Duration = .seconds(1)) {
        self.fileURL = fileURL
        self.capacity = capacity
        self.debounce = debounce
        terminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.flush() }
        }
    }

    // MARK: Public API

    /// Apply the saved position for `url` to `controller`, if one exists.
    func restore(for url: URL?, into controller: ReaderController) {
        guard let url else { return }
        let key = Self.key(for: url)
        restoredKeys.insert(key)
        if Self.isReady(controller) {
            apply(key: key, url: url, to: controller)
            return
        }
        // PDFView not attached or document not loaded yet: retry once, then give up.
        restoring.insert(key)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            if Self.isReady(controller) { apply(key: key, url: url, to: controller) }
            restoring.remove(key)
        }
    }

    /// Record the controller's current position for `url`. Cheap: memory now, disk later.
    func save(for url: URL?, from controller: ReaderController) {
        guard let url, controller.pageCount > 0 else { return }
        let key = Self.key(for: url)
        loadIfNeeded()
        guard !restoring.contains(key) else { return }
        if positions[key] != nil, !restoredKeys.contains(key) { return }
        restoredKeys.insert(key)

        positions[key] = ReadingPosition(
            pageIndex: controller.currentPageIndex,
            scaleFactor: Double(controller.scaleFactor),
            autoScales: controller.autoScales,
            displayMode: controller.displayMode.rawValue,
            fileSize: Self.fileSize(of: url),
            updatedAt: Date()
        )
        evictIfNeeded()
        scheduleWrite()
    }

    /// Write pending changes to disk now.
    func flush() {
        writeTask?.cancel()
        writeTask = nil
        guard isDirty else { return }
        isDirty = false
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(positions).write(to: fileURL, options: .atomic)
            writeCount += 1
        } catch {
            log.error("Could not write positions: \(error.localizedDescription)")
        }
    }

    /// Saved position for `url`, for tests.
    func position(for url: URL) -> ReadingPosition? {
        loadIfNeeded()
        return positions[Self.key(for: url)]
    }

    // MARK: Internals

    static func key(for url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().path
    }

    private static let displayModes: [PDFDisplayMode] =
        [.singlePage, .singlePageContinuous, .twoUp, .twoUpContinuous]

    private static func isReady(_ controller: ReaderController) -> Bool {
        controller.pdfView != nil && controller.pageCount > 0
    }

    private static func fileSize(of url: URL) -> Int64? {
        // attributesOfItem, not resourceValues: URL caches resource values and would go stale.
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int64
    }

    private func apply(key: String, url: URL, to controller: ReaderController) {
        loadIfNeeded()
        guard let entry = positions[key],
              entry.fileSize == nil || entry.fileSize == Self.fileSize(of: url),
              entry.pageIndex >= 0, entry.pageIndex < controller.pageCount else { return }
        // PDFDisplayMode is an imported C enum: init(rawValue:) never fails, and an
        // out-of-range value makes PDFView raise NSRangeException. Match known cases only.
        if let mode = Self.displayModes.first(where: { $0.rawValue == entry.displayMode }) {
            controller.setDisplayMode(mode)
        }
        if entry.autoScales || !entry.scaleFactor.isFinite {
            controller.fitWidth()
        } else {
            controller.setScale(CGFloat(entry.scaleFactor))
        }
        controller.goToPage(index: entry.pageIndex)
    }

    private func loadIfNeeded() {
        guard !isLoaded else { return }
        isLoaded = true
        guard let data = try? Data(contentsOf: fileURL) else { return }  // missing: start empty
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            // Decode per entry so one malformed record does not discard the rest.
            let entries = try decoder.decode([String: LenientPosition].self, from: data)
            positions = entries.compactMapValues(\.value)
        } catch {
            log.error("Ignoring corrupt positions file: \(error.localizedDescription)")
        }
    }

    private func evictIfNeeded() {
        guard positions.count > capacity else { return }
        let oldest = positions.sorted { $0.value.updatedAt < $1.value.updatedAt }
            .prefix(positions.count - capacity)
        for (key, _) in oldest { positions[key] = nil }
    }

    private func scheduleWrite() {
        isDirty = true
        writeTask?.cancel()
        writeTask = Task { @MainActor [debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            flush()
        }
    }
}

/// Decodes a stored position, or nil if that one entry is malformed.
private struct LenientPosition: Decodable {
    let value: ReadingPosition?
    init(from decoder: Decoder) throws {
        value = try? ReadingPosition(from: decoder)
    }
}
