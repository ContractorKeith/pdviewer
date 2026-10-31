import PDFKit
import SwiftUI

/// Hosts PDFKit's PDFView. All behavior goes through ReaderController; this
/// view only creates the PDFView and hands it over.
struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument
    let controller: ReaderController

    final class Coordinator {
        let controller: ReaderController
        init(controller: ReaderController) { self.controller = controller }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.displaysPageBreaks = true
        view.interpolationQuality = .high
        controller.attach(view)
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        if view.document !== document {
            view.document = document
        }
    }

    static func dismantleNSView(_ view: PDFView, coordinator: Coordinator) {
        coordinator.controller.detach()
    }
}
