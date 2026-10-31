import SwiftUI

/// View menu: zoom and display mode.
struct ViewCommands: Commands {
    @FocusedValue(\.readerController) private var reader

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button("Zoom In") { reader?.zoomIn() }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(reader == nil)
            Button("Zoom Out") { reader?.zoomOut() }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(reader == nil)
            Button("Actual Size") { reader?.actualSize() }
                .keyboardShortcut("0", modifiers: .command)
                .disabled(reader == nil)
        }
    }
}
