import SwiftUI

/// Window toolbar: zoom, display mode, page position.
struct ReaderToolbar: ToolbarContent {
    let controller: ReaderController

    var body: some ToolbarContent {
        // Implemented in milestone 2.
        ToolbarItemGroup(placement: .primaryAction) {
            Button("Zoom In", systemImage: "plus.magnifyingglass") { controller.zoomIn() }
            Button("Zoom Out", systemImage: "minus.magnifyingglass") { controller.zoomOut() }
        }
    }
}
