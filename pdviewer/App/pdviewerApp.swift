import SwiftUI

/// App entry. A read-only document app: every window is one PDF.
/// DocumentGroup(viewing:) gives Open, Open Recent, tabs, and window
/// restoration through NSDocument without us writing any AppKit glue.
@main
struct PdviewerApp: App {
    var body: some Scene {
        DocumentGroup(viewing: PDFFileDocument.self) { config in
            ReaderView(document: config.document.pdf, fileURL: config.fileURL)
        }
        .commands {
            ReaderCommands()
        }
    }
}
