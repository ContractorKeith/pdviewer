import PDFKit
import Testing
@testable import pdviewer

@MainActor
final class SearchControllerTests {
    private var retained: [AnyObject] = []

    /// Three pages: "Apple" x2 on page 1, "apple" on page 2, "Banana" on page 3.
    /// Holds the PDFView strongly; SearchController only keeps it weakly.
    @MainActor private final class Harness {
        let view = PDFView(frame: CGRect(x: 0, y: 0, width: 600, height: 800))
        let search = SearchController()
    }

    private func makeSearch() -> (SearchController, PDFView) {
        let harness = Harness()
        harness.view.document = TextPDF.make(pages: ["Apple pie and Apple tart", "green apple", "Banana split"])
        harness.search.attach(harness.view)
        retained.append(harness)
        return (harness.search, harness.view)
    }

    /// Runs a search and waits (bounded) for the scan to finish.
    private func run(_ text: String, on search: SearchController) async {
        search.search(for: text)
        for _ in 0..<200 where search.isSearching {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    @Test func caseInsensitiveByDefault() async {
        let (search, _) = makeSearch()
        await run("apple", on: search)
        #expect(search.results.count == 3)
        #expect(search.currentIndex == 0)
        #expect(search.statusText == "1 of 3")
    }

    @Test func caseSensitiveToggle() async {
        let (search, _) = makeSearch()
        search.caseSensitive = true
        await run("Apple", on: search)
        #expect(search.results.count == 2)
    }

    @Test func noResults() async {
        let (search, _) = makeSearch()
        await run("zebra", on: search)
        #expect(search.results.isEmpty)
        #expect(search.currentIndex == nil)
        #expect(search.statusText == "No results")
    }

    @Test func nextAndPreviousWrap() async {
        let (search, _) = makeSearch()
        await run("apple", on: search)
        search.next(); search.next()
        #expect(search.currentIndex == 2)
        search.next()
        #expect(search.currentIndex == 0)
        search.previous()
        #expect(search.currentIndex == 2)
    }

    @Test func clearResets() async {
        let (search, view) = makeSearch()
        await run("apple", on: search)
        search.clear()
        #expect(search.results.isEmpty)
        #expect(search.currentIndex == nil)
        #expect(view.highlightedSelections == nil)
        #expect(!search.isSearching)
    }

    @Test func newQueryReplacesResults() async {
        let (search, _) = makeSearch()
        await run("apple", on: search)
        await run("banana", on: search)
        #expect(search.results.count == 1)
        #expect(search.results.first?.string?.lowercased() == "banana")
        #expect(search.currentIndex == 0)
    }

    @Test func debouncedTypingSearches() async {
        let (search, _) = makeSearch()
        search.query = "banana"
        #expect(search.results.isEmpty)
        for _ in 0..<100 where search.results.isEmpty {
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(search.results.count == 1)
    }

    /// Starting a second search while the first is mid-scan must not lose matches.
    /// Experiment: PDFKit posts exactly one end event per scan. For a scan cancelled
    /// mid-flight it is delivered synchronously inside `cancelFindString()`; a scan
    /// that finished naturally posts its event asynchronously, which can land after
    /// the next scan has started. `pendingScans` accounts for both.
    @Test(arguments: [0, 5])
    func rapidQueryChangeKeepsAllMatches(delayMs: Int) async {
        let line = String(repeating: "alpha beta gamma ", count: 20)
        let harness = Harness()
        harness.view.document = TextPDF.make(pages: Array(repeating: line, count: 200))
        harness.search.attach(harness.view)
        retained.append(harness)
        let search = harness.search

        await run("beta", on: search)
        let expected = search.results.count
        #expect(expected == 4000)

        search.search(for: "alpha")
        try? await Task.sleep(for: .milliseconds(delayMs))
        search.search(for: "beta")
        for _ in 0..<2000 where search.isSearching {
            try? await Task.sleep(for: .milliseconds(5))
        }
        // Let any stale end event arrive, then compare.
        try? await Task.sleep(for: .milliseconds(300))
        #expect(search.results.count == expected)
    }
}
