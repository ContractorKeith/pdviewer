import Observation
import PDFKit

/// Text search for one document window: query, incremental results,
/// highlight, next/previous. Attached to the PDFView by ReaderController.
@MainActor
@Observable
final class SearchController {
    private(set) weak var pdfView: PDFView?

    func attach(_ view: PDFView) {
        pdfView = view
    }

    func detach() {
        pdfView = nil
    }
}
