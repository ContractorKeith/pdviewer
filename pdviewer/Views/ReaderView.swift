import PDFKit
import SwiftUI

/// Root view for one document window. Integration point only: layout and
/// wiring. Feature views (sidebar, toolbar, find bar) own their own files.
struct ReaderView: View {
    let document: PDFDocument
    let fileURL: URL?

    @State private var controller = ReaderController()

    var body: some View {
        NavigationSplitView(columnVisibility: columnVisibility) {
            SidebarView(controller: controller)
                .navigationSplitViewColumnWidth(min: 160, ideal: 220, max: 400)
        } detail: {
            PDFKitView(document: document, controller: controller)
                .overlay(alignment: .top) {
                    if controller.isFindBarVisible {
                        FindBar(controller: controller)
                    }
                }
        }
        .frame(minWidth: 560, minHeight: 360)
        .toolbar { ReaderToolbar(controller: controller) }
        .navigationSubtitle(pageSubtitle)
        .focusedSceneValue(\.readerController, controller)
        .task { ReadingPositionStore.shared.restore(for: fileURL, into: controller) }
        .onChange(of: controller.currentPageIndex) { savePosition() }
        .onChange(of: controller.scaleFactor) { savePosition() }
        .onChange(of: controller.displayMode) { savePosition() }
    }

    private var columnVisibility: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { controller.isSidebarVisible ? .all : .detailOnly },
            set: { controller.isSidebarVisible = $0 != .detailOnly }
        )
    }

    private var pageSubtitle: String {
        guard controller.pageCount > 0 else { return "" }
        return "Page \(controller.currentPageIndex + 1) of \(controller.pageCount)"
    }

    private func savePosition() {
        ReadingPositionStore.shared.save(for: fileURL, from: controller)
    }
}
