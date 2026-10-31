import CoreImage
import PDFKit
import SwiftUI

/// Hosts PDFKit's PDFView. All behavior goes through ReaderController; this
/// view only creates the PDFView and hands it over.
struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument
    let controller: ReaderController
    @AppStorage(Preferences.invertColors) private var invertColors = false

    /// Invert plus a 180° hue shift keeps colors recognizable while making
    /// white pages dark.
    private static let invertFilters: [CIFilter] = {
        let invert = CIFilter(name: "CIColorInvert")!
        let hue = CIFilter(name: "CIHueAdjust")!
        hue.setValue(Double.pi, forKey: kCIInputAngleKey)
        return [invert, hue]
    }()

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
        // Limits first: setting them after autoScales on a zero-sized view
        // clamps the scale to the floor and silently turns auto-fit off.
        view.minScaleFactor = ReaderController.minScaleFactor
        view.maxScaleFactor = ReaderController.maxScaleFactor
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.displaysPageBreaks = true
        view.pageBreakMargins = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        view.backgroundColor = .underPageBackgroundColor
        view.interpolationQuality = .high
        controller.attach(view)
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        if view.document !== document {
            view.document = document
        }
        let wantsInvert = invertColors
        if (view.contentFilters.isEmpty) == wantsInvert {
            view.contentFilters = wantsInvert ? Self.invertFilters : []
        }
    }

    static func dismantleNSView(_ view: PDFView, coordinator: Coordinator) {
        coordinator.controller.detach()
    }
}
