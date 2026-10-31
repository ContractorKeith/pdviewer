import Observation
import PDFKit

/// Back/forward history of page destinations within one document window.
/// Attached to the PDFView by ReaderController. Only explicit jumps are
/// recorded; ordinary scrolling is not.
@MainActor
@Observable
final class NavigationHistory {
    static let maxEntries = 100

    private(set) weak var pdfView: PDFView?
    private(set) var backStack: [Int] = []
    private(set) var forwardStack: [Int] = []

    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }

    func attach(_ view: PDFView) {
        pdfView = view
    }

    func detach() {
        pdfView = nil
    }

    /// Records the current page, clears forward history, then navigates.
    func jump(to index: Int) {
        guard let current = currentIndex else { return }
        let target = clamp(index)
        guard target != current else { return }
        backStack.append(current)
        if backStack.count > Self.maxEntries { backStack.removeFirst() }
        forwardStack.removeAll()
        show(target)
    }

    func goBack() {
        guard let current = currentIndex, let target = backStack.popLast() else { return }
        forwardStack.append(current)
        show(target)
    }

    func goForward() {
        guard let current = currentIndex, let target = forwardStack.popLast() else { return }
        backStack.append(current)
        show(target)
    }

    private var currentIndex: Int? {
        guard let doc = pdfView?.document, let page = pdfView?.currentPage else { return nil }
        let index = doc.index(for: page)
        return index == NSNotFound ? nil : index
    }

    private func clamp(_ index: Int) -> Int {
        min(max(index, 0), max((pdfView?.document?.pageCount ?? 1) - 1, 0))
    }

    private func show(_ index: Int) {
        guard let view = pdfView, let page = view.document?.page(at: index) else { return }
        view.go(to: page)
    }
}
