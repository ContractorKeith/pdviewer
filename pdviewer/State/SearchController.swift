import AppKit
import Observation
import PDFKit

/// Text search for one document window: query, streaming results, highlight,
/// next/previous. Attached to the PDFView by ReaderController.
///
/// Async strategy: `PDFDocument.beginFindString` + `PDFDocumentDelegate`. PDFKit
/// scans pages off the main thread and calls back on main per match, so results
/// stream in on a 4000-page file, no non-Sendable PDFKit objects cross actors,
/// and `cancelFindString()` cancels cleanly when the query changes.
@MainActor
@Observable
final class SearchController {
    private(set) weak var pdfView: PDFView?

    var query = "" {
        didSet { if query != oldValue { scheduleSearch() } }
    }
    var caseSensitive = false {
        didSet { if caseSensitive != oldValue { search() } }
    }
    private(set) var results: [PDFSelection] = []
    private(set) var currentIndex: Int?
    private(set) var isSearching = false
    /// Bumped to ask the find bar to (re)focus its field.
    private(set) var focusRequest = 0

    @ObservationIgnored private var debounceTask: Task<Void, Never>?
    @ObservationIgnored private var flushTask: Task<Void, Never>?
    @ObservationIgnored private var highlightsDirty = false
    /// Find-end events received (diagnostic, used by tests).
    @ObservationIgnored private(set) var endEventCount = 0
    /// Scans begun minus end events seen. PDFKit posts one end event per scan,
    /// cancelled or not, and a finished scan's event can arrive after the next
    /// scan starts, so only the last outstanding event ends the current scan.
    @ObservationIgnored private var pendingScans = 0
    @ObservationIgnored private weak var searchedDocument: PDFDocument?
    @ObservationIgnored private let delegateProxy = DelegateProxy()

    private static let matchColor = NSColor.systemYellow.withAlphaComponent(0.5)
    private static let currentColor = NSColor.systemOrange

    init() { delegateProxy.owner = self }

    var statusText: String {
        if query.isEmpty { return "" }
        if let index = currentIndex { return "\(index + 1) of \(results.count)" + (isSearching ? "…" : "") }
        return isSearching ? "Searching…" : "No results"
    }

    // MARK: Attach / detach

    func attach(_ view: PDFView) {
        detach()
        pdfView = view
    }

    func detach() {
        clear()
        pdfView = nil
    }

    func requestFocus() { focusRequest += 1 }

    // MARK: Searching

    /// Typing path: wait ~200 ms for a pause before scanning.
    private func scheduleSearch() {
        debounceTask?.cancel()
        guard !query.isEmpty else { search(); return }
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            self?.search()
        }
    }

    /// Sets the query and searches immediately (no debounce).
    func search(for text: String) {
        query = text
        search()
    }

    /// Cancels any running scan, then starts a new one for the current query.
    func search() {
        debounceTask?.cancel()
        stopScan()
        resetResults()
        guard let doc = pdfView?.document, !query.isEmpty else { return }
        searchedDocument = doc
        doc.delegate = delegateProxy
        isSearching = true
        pendingScans += 1
        let options: NSString.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
        doc.beginFindString(query, withOptions: options)
    }

    private func stopScan() {
        searchedDocument?.cancelFindString()
        if searchedDocument?.delegate === delegateProxy { searchedDocument?.delegate = nil }
        searchedDocument = nil
        isSearching = false
    }

    private func resetResults() {
        flushTask?.cancel()
        flushTask = nil
        highlightsDirty = false
        results = []
        currentIndex = nil
        pdfView?.highlightedSelections = nil
        pdfView?.setCurrentSelection(nil, animate: false)
    }

    /// Empties results, highlights, and selection (find bar closed).
    func clear() {
        debounceTask?.cancel()
        stopScan()
        resetResults()
    }

    // MARK: Navigation

    func next() { step(by: 1) }
    func previous() { step(by: -1) }

    private func step(by delta: Int) {
        guard !results.isEmpty else { return }
        let count = results.count
        let start = currentIndex ?? (delta > 0 ? -1 : 0)
        select(((start + delta) % count + count) % count)
    }

    private func select(_ index: Int) {
        guard let view = pdfView, results.indices.contains(index) else { return }
        if let old = currentIndex, results.indices.contains(old) { results[old].color = Self.matchColor }
        currentIndex = index
        let selection = results[index]
        selection.color = Self.currentColor
        view.setCurrentSelection(selection, animate: true)
        view.go(to: selection)
        applyHighlights()
    }

    // MARK: Delegate events (main actor)

    fileprivate func didMatch(_ selection: PDFSelection) {
        // Drop stragglers from a cancelled scan of a different query.
        guard isSearching, matchesQuery(selection) else { return }
        selection.color = Self.matchColor
        results.append(selection)
        if currentIndex == nil { select(0) }
        scheduleHighlightFlush()
    }

    /// NFKC folding so ligatures in the PDF text ("ﬁle") still match the query ("file").
    private func matchesQuery(_ selection: PDFSelection) -> Bool {
        guard let text = selection.string?.precomposedStringWithCompatibilityMapping else { return false }
        var options: String.CompareOptions = [.diacriticInsensitive, .widthInsensitive]
        if !caseSensitive { options.insert(.caseInsensitive) }
        return text.compare(query.precomposedStringWithCompatibilityMapping, options: options) == .orderedSame
    }

    fileprivate func didEndFind() {
        endEventCount += 1
        pendingScans = max(0, pendingScans - 1)
        guard isSearching, pendingScans == 0 else { return }
        isSearching = false
        applyHighlights()
    }

    /// Highlights are batched while results stream so a common word on a
    /// huge document doesn't rebuild the highlight list per match.
    private func scheduleHighlightFlush() {
        highlightsDirty = true
        guard flushTask == nil else { return }
        flushTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled, let self else { return }
            self.flushTask = nil
            if self.highlightsDirty { self.applyHighlights() }
        }
    }

    private func applyHighlights() {
        highlightsDirty = false
        pdfView?.highlightedSelections = results.isEmpty ? nil : results
    }

    /// PDFDocumentDelegate needs an NSObject; keep that out of the observable class.
    /// PDFKit delivers find callbacks on the main thread, so a main-actor
    /// `@preconcurrency` conformance is safe (it asserts if that ever changes).
    @MainActor
    private final class DelegateProxy: NSObject, @preconcurrency PDFDocumentDelegate {
        weak var owner: SearchController?

        func didMatchString(_ instance: PDFSelection) { owner?.didMatch(instance) }

        func documentDidEndDocumentFind(_ notification: Notification) { owner?.didEndFind() }
    }
}
