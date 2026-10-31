import PDFKit
import XCTest

/// The one UI test: launch with a PDF, confirm it renders, and save screenshots.
/// Set PDVIEWER_SHOTS to a directory to also write PNGs there (see `make uitest`).
final class SmokeUITests: XCTestCase {
    private var app: XCUIApplication!

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Open a generated PDF from the app's own sandbox container so the path is readable.
        let pdf = try Self.writeFixture()
        app.launchArguments = ["-ApplePersistenceIgnoreState", "YES", pdf.path]
        app.launch()
    }

    @MainActor
    func testOpensAndRendersPDF() throws {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 15), "document window did not appear")
        XCTAssertTrue(window.title.hasPrefix("smoke.pdf"), "title was \(window.title)")
        XCTAssertTrue(app.staticTexts["Page 1 of 5"].waitForExistence(timeout: 10)
                      || window.title.contains("Page 1 of 5"))
        save(window.screenshot(), name: "smoke-thumbnails")

        // Outline sidebar.
        app.menuBars.menuItems["Show Outline"].click()
        XCTAssertTrue(app.staticTexts["Chapter 2"].waitForExistence(timeout: 5), "outline did not show")
        save(window.screenshot(), name: "smoke-outline")

        // Find bar.
        app.typeKey("f", modifierFlags: .command)
        app.typeText("gamma")
        XCTAssertTrue(app.staticTexts["1 of 5"].waitForExistence(timeout: 10), "search found nothing")
        save(window.screenshot(), name: "smoke-find")

        // Invert colors (persists in UserDefaults, so toggle it back).
        app.typeKey(.escape, modifierFlags: [])
        app.menuBars.menuItems["Invert Colors"].click()
        save(window.screenshot(), name: "smoke-invert")
        app.menuBars.menuItems["Invert Colors"].click()

        // Key equivalents validate the File menu; a viewer must never end up "Locked".
        XCTAssertFalse(window.title.contains("Locked"), "document should not be locked: \(window.title)")
    }

    // MARK: Helpers

    private func save(_ shot: XCUIScreenshot, name: String) {
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = ProcessInfo.processInfo.environment["PDVIEWER_SHOTS"] {
            let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
            do { try shot.pngRepresentation.write(to: url) } catch { NSLog("screenshot: \(error)") }
        }
    }

    /// Five text pages with an outline, written into the app's container.
    private static func writeFixture() throws -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dir = home.appending(path: "Library/Containers/com.contractorkeith.pdviewer/Data/Documents")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appending(path: "smoke.pdf")

        let doc = TextPDF.make(pages: (1...5).map { i in
            "Chapter \(i)\n\nalpha beta gamma delta. Page \(i) of the smoke test."
        })
        let root = PDFOutline()
        for i in 0..<5 {
            let item = PDFOutline()
            item.label = "Chapter \(i + 1)"
            if let page = doc.page(at: i) { item.destination = PDFDestination(page: page, at: CGPoint(x: 0, y: 792)) }
            root.insertChild(item, at: i)
        }
        doc.outlineRoot = root
        guard doc.write(to: url) else { throw CocoaError(.fileWriteUnknown) }
        return url
    }
}
