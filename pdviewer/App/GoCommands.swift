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
            // First/Last are big jumps, so they go through history.
            Button("First Page") { reader?.history.jump(to: 0) }
                .keyboardShortcut(.upArrow, modifiers: .command)
                .disabled(reader?.canGoToPreviousPage != true)
            Button("Last Page") { reader.map { $0.history.jump(to: $0.pageCount - 1) } }
                .keyboardShortcut(.downArrow, modifiers: .command)
                .disabled(reader?.canGoToNextPage != true)

            Divider()

            Button("Go to Page\u{2026}") { reader?.isGoToPagePresented = true }
                .keyboardShortcut("g", modifiers: [.command, .option])
                .disabled(reader == nil)

            Divider()

            Button("Back") { reader?.history.goBack() }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(reader?.history.canGoBack != true)
            Button("Forward") { reader?.history.goForward() }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(reader?.history.canGoForward != true)
        }
    }
}
