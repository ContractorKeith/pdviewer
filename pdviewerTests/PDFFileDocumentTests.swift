import PDFKit
import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import pdviewer

/// Builds a small in-memory PDF so tests need no fixture files.
enum TestPDF {
    static func make(pages: Int = 3) -> Data {
        let doc = PDFDocument()
        for i in 0..<pages {
            doc.insert(PDFPage(), at: i)
        }
        return doc.dataRepresentation()!
    }
}

struct PDFFileDocumentTests {
    @Test func opensValidPDF() throws {
        let doc = try PDFFileDocument(data: TestPDF.make(pages: 3))
        #expect(doc.pdf.pageCount == 3)
    }

    @Test func rejectsGarbage() {
        #expect(throws: (any Error).self) {
            try PDFFileDocument(data: Data("not a pdf".utf8))
        }
    }

    @Test func isReadOnly() {
        #expect(PDFFileDocument.writableContentTypes.isEmpty)
        #expect(PDFFileDocument.readableContentTypes == [.pdf])
    }
}
