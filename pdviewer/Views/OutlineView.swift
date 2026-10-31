import PDFKit
import SwiftUI

/// Document outline (table of contents). Click jumps through history.
struct OutlineView: View {
    let controller: ReaderController
    @State private var items: [OutlineItem] = []

    var body: some View {
        Group {
            if items.isEmpty {
                Text("No Outline")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                list
            }
        }
        // Rebuild only when the document changes, not on every page change.
        .task(id: controller.pdfView.map(ObjectIdentifier.init)) {
            items = controller.pdfView?.document.map(OutlineItem.build(from:)) ?? []
        }
    }

    private var list: some View {
        let current = OutlineItem.currentID(in: items, page: controller.currentPageIndex)
        return List(items, children: \.children) { item in
            Button {
                if let index = item.pageIndex { controller.history.jump(to: index) }
            } label: {
                Text(item.label)
                    .fontWeight(item.id == current ? .bold : .regular)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(item.pageIndex == nil)
        }
        .listStyle(.sidebar)
    }
}
