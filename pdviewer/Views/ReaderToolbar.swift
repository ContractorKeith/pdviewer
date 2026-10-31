import PDFKit
import SwiftUI

/// Window toolbar: zoom, display mode, page position.
struct ReaderToolbar: ToolbarContent {
    let controller: ReaderController
    var fileURL: URL?

    private static let presets = [50, 75, 100, 125, 150, 200, 300, 400]

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            PageField(controller: controller)
        }
        ToolbarItemGroup(placement: .primaryAction) {
            if let fileURL {
                ShareLink(item: fileURL) { Label("Share", systemImage: "square.and.arrow.up") }
                    .help("Share")
                    .accessibilityLabel("Share")
            }
            Menu {
                Picker("Display Mode", selection: displayMode) {
                    ForEach(DisplayModeOption.allCases) { option in
                        Label(option.title, systemImage: option.symbol).tag(option.mode)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Label("Display Mode", systemImage: DisplayModeOption.option(for: controller.displayMode).symbol)
            }
            .help("Display Mode")
            .accessibilityLabel("Display Mode")

            Button("Zoom Out", systemImage: "minus.magnifyingglass") { controller.zoomOut() }
                .help("Zoom Out")
                .accessibilityLabel("Zoom Out")
            Menu(zoomLabel) {
                Button("Fit Width") { controller.fitWidth() }
                Button("Fit Page") { controller.fitPage() }
                Button("Actual Size") { controller.actualSize() }
                Divider()
                ForEach(Self.presets, id: \.self) { percent in
                    Button("\(percent)%") { controller.setScale(CGFloat(percent) / 100) }
                }
            }
            .help("Zoom")
            .accessibilityLabel("Zoom")
            .accessibilityValue(zoomLabel)
            Button("Zoom In", systemImage: "plus.magnifyingglass") { controller.zoomIn() }
                .help("Zoom In")
                .accessibilityLabel("Zoom In")
        }
    }

    private var zoomLabel: String {
        controller.autoScales ? "Fit \(controller.zoomPercent)%" : "\(controller.zoomPercent)%"
    }

    private var displayMode: Binding<PDFDisplayMode> {
        Binding(get: { controller.displayMode }, set: { controller.setDisplayMode($0) })
    }
}

/// The four PDFView display modes with their menu titles and symbols.
enum DisplayModeOption: CaseIterable, Identifiable {
    case single, singleContinuous, twoUp, twoUpContinuous

    var id: Self { self }

    static func option(for mode: PDFDisplayMode) -> DisplayModeOption {
        allCases.first { $0.mode == mode } ?? .singleContinuous
    }

    var mode: PDFDisplayMode {
        switch self {
        case .single: .singlePage
        case .singleContinuous: .singlePageContinuous
        case .twoUp: .twoUp
        case .twoUpContinuous: .twoUpContinuous
        }
    }

    var title: String {
        switch self {
        case .single: "Single Page"
        case .singleContinuous: "Single Page Continuous"
        case .twoUp: "Two Pages"
        case .twoUpContinuous: "Two Pages Continuous"
        }
    }

    var symbol: String {
        switch self {
        case .single: "doc"
        case .singleContinuous: "doc.text"
        case .twoUp: "book"
        case .twoUpContinuous: "book.pages"
        }
    }
}

/// Editable page number with an "of N" label. Shows the live page unless the
/// user is typing; commits on Enter, discards on blur.
private struct PageField: View {
    let controller: ReaderController
    @State private var draft: String?
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 4) {
            TextField("Page", text: text)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 52)
                .focused($focused)
                .onSubmit(commit)
                .onChange(of: focused) { if !focused { draft = nil } }
                .help("Go to Page")
                .accessibilityLabel("Page Number")
            Text("of \(controller.pageCount)")
                .foregroundStyle(.secondary)
                .accessibilityLabel("of \(controller.pageCount) pages")
        }
        .disabled(controller.pageCount == 0)
    }

    private var text: Binding<String> {
        Binding(
            get: { draft ?? (controller.pageCount == 0 ? "" : "\(controller.currentPageIndex + 1)") },
            set: { draft = $0 }
        )
    }

    private func commit() {
        controller.submitPageNumber(draft ?? "")
        draft = nil
        focused = false
    }
}
