import PDFKit
import Testing
@testable import pdviewer

struct OutlineItemTests {
    private func node(_ label: String, page: PDFPage) -> PDFOutline {
        let outline = PDFOutline()
        outline.label = label
        outline.destination = PDFDestination(page: page, at: .zero)
        return outline
    }

    @Test func buildsNestedTree() throws {
        let doc = try #require(PDFDocument(data: TestPDF.make(pages: 5)))
        let root = PDFOutline()
        let ch1 = node("Chapter 1", page: try #require(doc.page(at: 0)))
        let sec = node("Section 1.1", page: try #require(doc.page(at: 2)))
        let ch2 = node("Chapter 2", page: try #require(doc.page(at: 4)))
        ch1.insertChild(sec, at: 0)
        root.insertChild(ch1, at: 0)
        root.insertChild(ch2, at: 1)
        doc.outlineRoot = root

        let items = OutlineItem.build(from: doc)
        #expect(items.map(\.label) == ["Chapter 1", "Chapter 2"])
        #expect(items.map(\.pageIndex) == [0, 4])
        #expect(items[0].children?.map(\.pageIndex) == [2])
        #expect(items[1].children == nil)
        #expect(OutlineItem.currentID(in: items, page: 3) == items[0].children?[0].id)
    }

    @Test func noOutlineIsEmpty() throws {
        let doc = try #require(PDFDocument(data: TestPDF.make(pages: 2)))
        #expect(OutlineItem.build(from: doc).isEmpty)
    }
}
