import SwiftUI

/// Edit > Find submenu.
struct FindCommands: Commands {
    @FocusedValue(\.readerController) private var reader

    var body: some Commands {
        CommandGroup(after: .pasteboard) {
            Menu("Find") {
                Button("Find…") {
                    reader?.isFindBarVisible = true
                    reader?.search.requestFocus()
                }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(reader == nil)

                Button("Find Next") { reader?.search.next() }
                    .keyboardShortcut("g", modifiers: .command)
                    .disabled(!hasResults)

                Button("Find Previous") { reader?.search.previous() }
                    .keyboardShortcut("g", modifiers: [.command, .shift])
                    .disabled(!hasResults)

                Button("Use Selection for Find") { useSelection() }
                    .keyboardShortcut("e", modifiers: .command)
                    .disabled(reader == nil)

                Button("Hide Find Bar") {
                    reader?.isFindBarVisible = false
                    reader?.search.clear()
                }
                .disabled(reader?.isFindBarVisible != true)
            }
        }
    }

    private var hasResults: Bool { !(reader?.search.results.isEmpty ?? true) }

    private func useSelection() {
        guard let reader, let text = reader.pdfView?.currentSelection?.string,
              !text.isEmpty else { return }
        reader.isFindBarVisible = true
        reader.search.search(for: text.trimmingCharacters(in: .whitespacesAndNewlines))
        reader.search.requestFocus()
    }
}
