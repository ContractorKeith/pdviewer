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
        view.minScaleFactor = Self.minScaleFactor
        view.maxScaleFactor = Self.maxScaleFactor
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

    /// Copies PDFView state into the mirrored properties. Called from notifications.
    func refresh() {
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

    static let minScaleFactor: CGFloat = 0.25
    static let maxScaleFactor: CGFloat = 8
    private static let zoomStep: CGFloat = 1.25

    /// Current zoom as a whole percentage.
    var zoomPercent: Int { Int((scaleFactor * 100).rounded()) }

    func zoomIn() { setScale((pdfView?.scaleFactor ?? 1) * Self.zoomStep) }
    func zoomOut() { setScale((pdfView?.scaleFactor ?? 1) / Self.zoomStep) }

    func actualSize() { setScale(1) }

    /// Fit page width to the view. PDFKit's autoScales does exactly this.
    func fitWidth() {
        pdfView?.autoScales = true
    }

    /// Fit the whole current page (width and height) in the view.
    func fitPage() {
        guard let view = pdfView else { return }
        let fallback = view.scaleFactorForSizeToFit
        guard let page = view.currentPage else { return setScale(fallback) }
        var size = page.bounds(for: view.displayBox).size
        if page.rotation % 180 != 0 { size = CGSize(width: size.height, height: size.width) }
        let margins = view.displaysPageBreaks ? view.pageBreakMargins : NSEdgeInsets()
        let available = CGSize(
            width: view.bounds.width - margins.left - margins.right,
            height: view.bounds.height - margins.top - margins.bottom
        )
        guard size.width > 0, size.height > 0, available.width > 0, available.height > 0 else {
            return setScale(fallback)
        }
        setScale(min(available.width / size.width, available.height / size.height))
    }

    /// Fixed scale, clamped to the zoom limits. Turns off fit-to-width.
    func setScale(_ scale: CGFloat) {
        guard let view = pdfView else { return }
        view.autoScales = false
        view.scaleFactor = min(max(scale, Self.minScaleFactor), Self.maxScaleFactor)
    }

    func setDisplayMode(_ mode: PDFDisplayMode) {
        pdfView?.displayMode = mode
    }
}
