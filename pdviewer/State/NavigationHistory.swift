import Observation
import PDFKit

/// Back/forward history of page destinations within one document window.
/// Attached to the PDFView by ReaderController.
@MainActor
@Observable
final class NavigationHistory {
    private(set) weak var pdfView: PDFView?

    func attach(_ view: PDFView) {
        pdfView = view
    }

    func detach() {
        pdfView = nil
    }
}
