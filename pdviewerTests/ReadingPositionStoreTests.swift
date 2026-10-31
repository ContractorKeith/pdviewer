import PDFKit
import Testing
@testable import pdviewer

@MainActor
struct ReadingPositionStoreTests {
    /// Fresh temp dir per test; returns the positions.json URL and a fake "pdf" file URL.
    private func makePaths(fileBytes: Int = 100) throws -> (store: URL, pdf: URL) {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let pdf = dir.appending(path: "doc.pdf")
        try Data(count: fileBytes).write(to: pdf)
        return (dir.appending(path: "sub/positions.json"), pdf)
    }

    private func makeController(pages: Int = 10) -> (ReaderController, PDFView) {
        let view = PDFView(frame: NSRect(x: 0, y: 0, width: 600, height: 800))
        view.document = PDFDocument(data: TestPDF.make(pages: pages))
        let controller = ReaderController()
        controller.attach(view)
        return (controller, view)
    }

    @Test func roundTripRestoresPageAndZoom() throws {
        let paths = try makePaths()
        let (c1, _) = makeController()
        c1.goToPage(index: 6)
        c1.setScale(1.75)
        let store = ReadingPositionStore(fileURL: paths.store)
        store.save(for: paths.pdf, from: c1)
        store.flush()

        let (c2, _) = makeController()
        ReadingPositionStore(fileURL: paths.store).restore(for: paths.pdf, into: c2)
        #expect(c2.currentPageIndex == 6)
        #expect(c2.autoScales == false)
        #expect(abs(c2.scaleFactor - 1.75) < 0.01)
    }

    @Test func pageBeyondCountSkipsRestore() throws {
        let paths = try makePaths()
        let (c1, _) = makeController(pages: 10)
        c1.goToPage(index: 8)
        let store = ReadingPositionStore(fileURL: paths.store)
        store.save(for: paths.pdf, from: c1)
        store.flush()

        let (c2, _) = makeController(pages: 3)
        ReadingPositionStore(fileURL: paths.store).restore(for: paths.pdf, into: c2)
        #expect(c2.currentPageIndex == 0)
    }

    @Test func fileSizeMismatchSkipsRestore() throws {
        let paths = try makePaths(fileBytes: 100)
        let (c1, _) = makeController()
        c1.goToPage(index: 4)
        let store = ReadingPositionStore(fileURL: paths.store)
        store.save(for: paths.pdf, from: c1)
        store.flush()
        try Data(count: 250).write(to: paths.pdf)

        let (c2, _) = makeController()
        ReadingPositionStore(fileURL: paths.store).restore(for: paths.pdf, into: c2)
        #expect(c2.currentPageIndex == 0)
    }

    @Test func corruptFileStartsEmpty() throws {
        let paths = try makePaths()
        try FileManager.default.createDirectory(
            at: paths.store.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{ not json".utf8).write(to: paths.store)
        let store = ReadingPositionStore(fileURL: paths.store)
        #expect(store.position(for: paths.pdf) == nil)

        let (c, _) = makeController()
        c.goToPage(index: 2)
        store.save(for: paths.pdf, from: c)
        #expect(store.position(for: paths.pdf)?.pageIndex == 2)
    }

    @Test func evictsOldestBeyondCapacity() throws {
        let paths = try makePaths()
        let store = ReadingPositionStore(fileURL: paths.store, capacity: 3)
        let (c, _) = makeController()
        let dir = paths.pdf.deletingLastPathComponent()
        let urls = (0..<5).map { dir.appending(path: "f\($0).pdf") }
        for url in urls {
            store.save(for: url, from: c)
            Thread.sleep(forTimeInterval: 0.01)  // distinct updatedAt
        }
        #expect(store.position(for: urls[0]) == nil)
        #expect(store.position(for: urls[1]) == nil)
        for url in urls[2...] { #expect(store.position(for: url) != nil) }
    }

    @Test func debounceCoalescesWrites() throws {
        let paths = try makePaths()
        let store = ReadingPositionStore(fileURL: paths.store, debounce: .seconds(60))
        let (c, _) = makeController()
        store.save(for: paths.pdf, from: c)
        c.goToPage(index: 3)
        store.save(for: paths.pdf, from: c)
        #expect(store.writeCount == 0)
        store.flush()
        store.flush()  // nothing dirty: no second write
        #expect(store.writeCount == 1)
        #expect(FileManager.default.fileExists(atPath: paths.store.path))
    }

    @Test func savesAreIgnoredBeforeRestoreOverwritesExistingEntry() throws {
        let paths = try makePaths()
        let (c1, _) = makeController()
        c1.goToPage(index: 5)
        let first = ReadingPositionStore(fileURL: paths.store)
        first.save(for: paths.pdf, from: c1)
        first.flush()

        // New session: a stray page-0 save arrives before restore runs.
        let second = ReadingPositionStore(fileURL: paths.store)
        let (c2, _) = makeController()
        second.save(for: paths.pdf, from: c2)
        second.restore(for: paths.pdf, into: c2)
        #expect(c2.currentPageIndex == 5)
    }
}
