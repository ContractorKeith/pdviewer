import Observation
import PDFKit

/// Which list the sidebar shows.
enum SidebarMode: String, CaseIterable, Identifiable {
    case thumbnails, outline
    var id: String { rawValue }
}

/// One per window. Owns the PDFView reference and exposes every reader action
/// (paging, zoom, display mode) so views, toolbar, and menu commands share one
/// seam. Views observe the mirrored state properties; they never read PDFView
/// directly. Feature-specific logic lives in the sub-controllers below.
@MainActor
@Observable
final class ReaderController {
    private(set) weak var pdfView: PDFView?

    // Mirrored PDFView state, refreshed from notifications.
    private(set) var currentPageIndex = 0
    private(set) var pageCount = 0
    private(set) var scaleFactor: CGFloat = 1
    private(set) var autoScales = true
    private(set) var displayMode: PDFDisplayMode = .singlePageContinuous

    // UI state shared by sidebar, find bar, and menu commands.
    var isSidebarVisible = true
    var sidebarMode: SidebarMode = .thumbnails
    var isFindBarVisible = false
    var isGoToPagePresented = false

    // Sub-controllers. Each owns one feature and attaches to the same PDFView.
    let search = SearchController()
    let history = NavigationHistory()

    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    // MARK: Attach / detach

    func attach(_ view: PDFView) {
        detach()
        pdfView = view
        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            .PDFViewPageChanged, .PDFViewScaleChanged, .PDFViewDocumentChanged, .PDFViewDisplayModeChanged
        ]
        observers = names.map { name in
            center.addObserver(forName: name, object: view, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        }
        search.attach(view)
        history.attach(view)
        refresh()
    }

    func detach() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
        search.detach()
        history.detach()
        pdfView = nil
    }

    private func refresh() {
        guard let view = pdfView else { return }
        pageCount = view.document?.pageCount ?? 0
        if let page = view.currentPage, let index = view.document?.index(for: page) {
            currentPageIndex = index
        }
        scaleFactor = view.scaleFactor
        autoScales = view.autoScales
        displayMode = view.displayMode
    }

    // MARK: Paging

    var canGoToNextPage: Bool { pdfView?.canGoToNextPage ?? false }
    var canGoToPreviousPage: Bool { pdfView?.canGoToPreviousPage ?? false }

    func nextPage() { pdfView?.goToNextPage(nil) }
    func previousPage() { pdfView?.goToPreviousPage(nil) }
    func firstPage() { pdfView?.goToFirstPage(nil) }
    func lastPage() { pdfView?.goToLastPage(nil) }

    /// Zero-based. Out-of-range values are clamped.
    func goToPage(index: Int) {
        guard let view = pdfView, let doc = view.document, doc.pageCount > 0 else { return }
        let clamped = min(max(index, 0), doc.pageCount - 1)
        if let page = doc.page(at: clamped) { view.go(to: page) }
    }

    // MARK: Zoom

    func zoomIn() { pdfView?.zoomIn(nil) }
    func zoomOut() { pdfView?.zoomOut(nil) }

    func actualSize() {
        guard let view = pdfView else { return }
        view.autoScales = false
        view.scaleFactor = 1
    }

    /// Fit page width to the view. PDFKit's autoScales does exactly this.
    func fitWidth() {
        pdfView?.autoScales = true
    }

    func fitPage() {
        guard let view = pdfView else { return }
        view.autoScales = false
        view.scaleFactor = view.scaleFactorForSizeToFit
    }

    func setScale(_ scale: CGFloat) {
        guard let view = pdfView else { return }
        view.autoScales = false
        view.scaleFactor = min(max(scale, view.minScaleFactor), view.maxScaleFactor)
    }

    func setDisplayMode(_ mode: PDFDisplayMode) {
        pdfView?.displayMode = mode
    }
}
