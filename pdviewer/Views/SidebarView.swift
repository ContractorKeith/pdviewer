import SwiftUI

/// Sidebar: thumbnails or outline, picked by `controller.sidebarMode`.
struct SidebarView: View {
    @Bindable var controller: ReaderController

    var body: some View {
        VStack(spacing: 0) {
            Picker("Sidebar", selection: $controller.sidebarMode) {
                Label("Thumbnails", systemImage: "square.grid.2x2").tag(SidebarMode.thumbnails)
                Label("Outline", systemImage: "list.bullet.indent").tag(SidebarMode.outline)
            }
            .pickerStyle(.segmented)
            .labelStyle(.iconOnly)
            .labelsHidden()
            .padding(8)

            switch controller.sidebarMode {
            case .thumbnails:
                ThumbnailsView(controller: controller)
            case .outline:
                OutlineView(controller: controller)
            }
        }
    }
}
