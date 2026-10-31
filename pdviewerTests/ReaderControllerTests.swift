import PDFKit
import Testing
@testable import pdviewer

@MainActor
struct ReaderControllerTests {
    /// Controller attached to a window-less PDFView holding a 5-page document.
    private func makeReader(pages: Int = 5) -> (ReaderController, PDFView) {
        let view = PDFView(frame: NSRect(x: 0, y: 0, width: 600, height: 800))
        view.document = PDFDocument(data: TestPDF.make(pages: pages))
        let controller = ReaderController()
        controller.attach(view)
        return (controller, view)
    }

    private func pageIndex(_ view: PDFView) -> Int? {
        view.currentPage.flatMap { view.document?.index(for: $0) }
    }

    @Test func mirrorsPageCount() {
        let (controller, _) = makeReader()
        #expect(controller.pageCount == 5)
    }

    @Test func goToPageClamps() {
        let (controller, view) = makeReader()
        controller.goToPage(index: 2)
        #expect(pageIndex(view) == 2)
        controller.goToPage(index: -10)
        #expect(pageIndex(view) == 0)
        controller.goToPage(index: 99)
        #expect(pageIndex(view) == 4)
        controller.refresh()
        #expect(controller.currentPageIndex == 4)
    }

    @Test func setScaleClamps() {
        let (controller, view) = makeReader()
        controller.setScale(100)
        #expect(view.scaleFactor == ReaderController.maxScaleFactor)
        controller.setScale(0.001)
        #expect(view.scaleFactor == ReaderController.minScaleFactor)
    }

    @Test func zoomStepsAreConsistent() {
        let (controller, view) = makeReader()
        controller.setScale(1)
        controller.zoomIn()
        #expect(abs(view.scaleFactor - 1.25) < 0.001)
        controller.zoomOut()
        #expect(abs(view.scaleFactor - 1) < 0.001)
    }

    @Test func mirrorsDisplayMode() {
        let (controller, _) = makeReader()
        controller.setDisplayMode(.twoUp)
        controller.refresh()
        #expect(controller.displayMode == .twoUp)
    }

    @Test func actualSizeDisablesAutoScale() {
        let (controller, _) = makeReader()
        controller.actualSize()
        controller.refresh()
        #expect(controller.scaleFactor == 1)
        #expect(controller.zoomPercent == 100)
        #expect(controller.autoScales == false)
    }

    @Test func fitWidthEnablesAutoScale() {
        let (controller, _) = makeReader()
        controller.actualSize()
        controller.fitWidth()
        controller.refresh()
        #expect(controller.autoScales)
    }

    @Test func attachKeepsAutoScales() {
        let view = PDFView(frame: .zero)
        view.document = PDFDocument(data: TestPDF.make(pages: 2))
        view.minScaleFactor = ReaderController.minScaleFactor
        view.maxScaleFactor = ReaderController.maxScaleFactor
        view.autoScales = true
        let controller = ReaderController()
        controller.attach(view)
        view.frame = NSRect(x: 0, y: 0, width: 600, height: 800)
        controller.refresh()
        #expect(controller.autoScales)
        #expect(view.scaleFactor > ReaderController.minScaleFactor)
    }

    @Test func fitPageSetsFixedScale() {
        let (controller, view) = makeReader()
        controller.fitPage()
        #expect(view.autoScales == false)
        #expect(view.scaleFactor >= ReaderController.minScaleFactor)
    }
}
