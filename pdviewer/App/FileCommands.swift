import SwiftUI

/// File menu additions: Print goes through PDFView so pages print correctly.
struct FileCommands: Commands {
    @FocusedValue(\.readerController) private var reader

    var body: some Commands {
        CommandGroup(replacing: .printItem) {
            Button("Print…") { reader?.print() }
                .keyboardShortcut("p", modifiers: .command)
                .disabled(reader == nil)
        }
    }
}
