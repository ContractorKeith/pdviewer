import PDFKit

/// Value-type snapshot of a PDFOutline tree for SwiftUI `List(children:)`.
struct OutlineItem: Identifiable, Hashable {
    let id: String
    let label: String
    let pageIndex: Int?
    /// nil when empty, so the List shows no disclosure triangle.
    let children: [OutlineItem]?

    /// Top-level items of the document outline (empty if none).
    static func build(from document: PDFDocument) -> [OutlineItem] {
        guard let root = document.outlineRoot else { return [] }
        return items(of: root, in: document, path: "")
    }

    private static func items(of node: PDFOutline, in document: PDFDocument, path: String) -> [OutlineItem] {
        (0..<node.numberOfChildren).compactMap { i in
            guard let child = node.child(at: i) else { return nil }
            let id = "\(path)/\(i)"
            var pageIndex: Int?
            if let page = child.destination?.page {
                let index = document.index(for: page)
                pageIndex = index == NSNotFound ? nil : index
            }
            let kids = items(of: child, in: document, path: id)
            return OutlineItem(id: id, label: child.label ?? "Untitled", pageIndex: pageIndex,
                               children: kids.isEmpty ? nil : kids)
        }
    }

    /// ID of the item with the greatest page at or before `page`.
    static func currentID(in items: [OutlineItem], page: Int) -> String? {
        var best: (id: String, page: Int)?
        func walk(_ list: [OutlineItem]) {
            for item in list {
                if let pg = item.pageIndex, pg <= page, pg >= (best?.page ?? -1) { best = (item.id, pg) }
                walk(item.children ?? [])
            }
        }
        walk(items)
        return best?.id
    }
}
