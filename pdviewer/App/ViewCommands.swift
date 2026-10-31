import PDFKit
import SwiftUI

/// View menu: zoom, display mode, sidebar.
struct ViewCommands: Commands {
    @FocusedValue(\.readerController) private var reader
    @AppStorage(Preferences.invertColors) private var invertColors = false

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Divider()
            Button("Zoom In") { reader?.zoomIn() }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(reader == nil)
            // US keyboards type "+" as ⇧=, so ⌘= needs its own binding.
            Button("Zoom In") { reader?.zoomIn() }
                .keyboardShortcut("=", modifiers: .command)
                .disabled(reader == nil)
                .hidden()
            Button("Zoom Out") { reader?.zoomOut() }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(reader == nil)
            Button("Actual Size") { reader?.actualSize() }
                .keyboardShortcut("0", modifiers: .command)
                .disabled(reader == nil)
            Button("Zoom to Fit Width") { reader?.fitWidth() }
                .keyboardShortcut("9", modifiers: .command)
                .disabled(reader == nil)
            Button("Fit Page") { reader?.fitPage() }
                .keyboardShortcut("9", modifiers: [.command, .shift])
                .disabled(reader == nil)

            Divider()
            Picker("Display Mode", selection: displayMode) {
                ForEach(DisplayModeOption.allCases) { option in
                    Text(option.title).tag(option.mode)
                }
            }
            .pickerStyle(.menu)
            .disabled(reader == nil)
            Toggle("Invert Colors", isOn: $invertColors)
                .keyboardShortcut("i", modifiers: [.command, .option])
        }
        // Replaces the system sidebar item so the menu has one toggle, not two.
        CommandGroup(replacing: .sidebar) {
            Button(reader?.isSidebarVisible == false ? "Show Sidebar" : "Hide Sidebar") {
                reader?.isSidebarVisible.toggle()
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
            .disabled(reader == nil)
            Button("Show Thumbnails") { showSidebar(.thumbnails) }
                .disabled(reader == nil)
            Button("Show Outline") { showSidebar(.outline) }
                .disabled(reader == nil)
        }
    }

    private var displayMode: Binding<PDFDisplayMode> {
        Binding(
            get: { reader?.displayMode ?? .singlePageContinuous },
            set: { reader?.setDisplayMode($0) }
        )
    }

    private func showSidebar(_ mode: SidebarMode) {
        reader?.sidebarMode = mode
        reader?.isSidebarVisible = true
    }
}
