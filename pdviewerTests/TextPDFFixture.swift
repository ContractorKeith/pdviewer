import AppKit
import PDFKit

/// Builds an in-memory PDF with real, searchable text (one string per page).
enum TextPDF {
    static func make(pages: [String]) -> PDFDocument {
        let data = NSMutableData()
        let consumer = CGDataConsumer(data: data as CFMutableData)!
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        let ctx = CGContext(consumer: consumer, mediaBox: &box, nil)!
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 18)]
        for text in pages {
            ctx.beginPDFPage(nil)
            let framesetter = CTFramesetterCreateWithAttributedString(
                NSAttributedString(string: text, attributes: attrs))
            let path = CGPath(rect: box.insetBy(dx: 50, dy: 50), transform: nil)
            CTFrameDraw(CTFramesetterCreateFrame(framesetter, CFRange(), path, nil), ctx)
            ctx.endPDFPage()
        }
        ctx.closePDF()
        return PDFDocument(data: data as Data)!
    }
}
