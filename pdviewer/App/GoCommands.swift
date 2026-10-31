import SwiftUI

/// Go menu: paging, go to page, back/forward history.
struct GoCommands: Commands {
    @FocusedValue(\.readerController) private var reader

    var body: some Commands {
        CommandMenu("Go") {
            Button("Next Page") { reader?.nextPage() }
                .keyboardShortcut(.rightArrow, modifiers: .command)
                .disabled(reader?.canGoToNextPage != true)
            Button("Previous Page") { reader?.previousPage() }
                .keyboardShortcut(.leftArrow, modifiers: .command)
                .disabled(reader?.canGoToPreviousPage != true)
        }
    }
}
