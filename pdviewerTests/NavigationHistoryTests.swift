import PDFKit
import Testing
@testable import pdviewer

@MainActor
struct NavigationHistoryTests {
    private func makeHistory(pages: Int = 10) -> (NavigationHistory, PDFView) {
        let view = PDFView()
        view.document = PDFDocument(data: TestPDF.make(pages: pages))
        let history = NavigationHistory()
        history.attach(view)
        return (history, view)
    }

    private func index(_ view: PDFView) -> Int {
        view.document!.index(for: view.currentPage!)
    }

    @Test func jumpRecordsAndGoesBack() {
        let (history, view) = makeHistory()
        history.jump(to: 5)
        #expect(index(view) == 5)
        #expect(history.canGoBack)
        history.goBack()
        #expect(index(view) == 0)
        #expect(!history.canGoBack)
        #expect(history.canGoForward)
        history.goForward()
        #expect(index(view) == 5)
    }

    @Test func newJumpClearsForward() {
        let (history, _) = makeHistory()
        history.jump(to: 3)
        history.goBack()
        #expect(history.canGoForward)
        history.jump(to: 7)
        #expect(!history.canGoForward)
    }

    @Test func jumpToSamePageIsIgnored() {
        let (history, _) = makeHistory()
        history.jump(to: 0)
        #expect(!history.canGoBack)
    }

    @Test func clampsOutOfRange() {
        let (history, view) = makeHistory()
        history.jump(to: 99)
        #expect(index(view) == 9)
    }

    @Test func capsAtMaxEntries() {
        let (history, _) = makeHistory()
        for i in 0..<150 { history.jump(to: i % 2 == 0 ? 1 : 2) }
        #expect(history.backStack.count == NavigationHistory.maxEntries)
    }
}
