import PDFKit
import SwiftUI

/// PDFKit's thumbnail strip. Setting `pdfView` syncs selection and scrolling.
struct ThumbnailsView: NSViewRepresentable {
    let controller: ReaderController

    func makeNSView(context: Context) -> PDFThumbnailView {
        let view = PDFThumbnailView()
        view.thumbnailSize = CGSize(width: 120, height: 160)
        view.backgroundColor = .clear
        view.pdfView = controller.pdfView
        return view
    }

    func updateNSView(_ view: PDFThumbnailView, context: Context) {
        // pdfView may have been nil at make time.
        if view.pdfView !== controller.pdfView { view.pdfView = controller.pdfView }
    }
}
