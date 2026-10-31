import SwiftUI

/// Edit > Find submenu.
struct FindCommands: Commands {
    @FocusedValue(\.readerController) private var reader

    var body: some Commands {
        // Implemented in milestone 4.
        CommandGroup(replacing: .textEditing) {
            Button("Find…") { reader?.isFindBarVisible = true }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(reader == nil)
        }
    }
}
