import SwiftUI

/// Composes the menu bar. Each feature owns its own Commands struct.
struct ReaderCommands: Commands {
    var body: some Commands {
        ViewCommands()
        GoCommands()
        FindCommands()
    }
}

extension FocusedValues {
    /// The reader for the focused window, published by ReaderView.
    @Entry var readerController: ReaderController?
}
