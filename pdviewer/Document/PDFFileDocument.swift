import PDFKit
import SwiftUI
import UniformTypeIdentifiers

/// Read-only document wrapper so SwiftUI's DocumentGroup can open PDFs.
/// PDFDocument is a class and not Sendable; it is only ever touched on the
/// main actor by PDFView, so the unchecked conformance is safe in practice.
struct PDFFileDocument: FileDocument, @unchecked Sendable {
    static let readableContentTypes: [UTType] = [.pdf]
    static let writableContentTypes: [UTType] = []

    let pdf: PDFDocument

    init(pdf: PDFDocument) {
        self.pdf = pdf
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        try self.init(data: data)
    }

    /// Testable entry point; DocumentGroup's ReadConfiguration has no public init.
    init(data: Data) throws {
        guard let pdf = PDFDocument(data: data) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.pdf = pdf
    }

    /// Never called by DocumentGroup(viewing:). Present to satisfy FileDocument.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = pdf.dataRepresentation() else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
