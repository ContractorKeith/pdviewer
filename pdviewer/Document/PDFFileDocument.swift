import PDFKit
import SwiftUI
import UniformTypeIdentifiers

/// Read-only document wrapper so SwiftUI's DocumentGroup can open PDFs.
/// PDFDocument is a class and not Sendable; it is only ever touched on the
/// main actor by PDFView, so the unchecked conformance is safe in practice.
struct PDFFileDocument: FileDocument, @unchecked Sendable {
    static let readableContentTypes: [UTType] = [.pdf]
    // Declared writable even though nothing ever edits: with no writable type,
    // NSDocument marks the window "Locked" as soon as a key equivalent
    // validates the File menu.
    static let writableContentTypes: [UTType] = [.pdf]

    let pdf: PDFDocument
    /// Original bytes, so Save/Duplicate write the file back unchanged
    /// instead of PDFKit's re-serialization.
    let data: Data

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
        self.data = data
    }

    /// Only reached through Save As / Duplicate; nothing in the app edits.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
