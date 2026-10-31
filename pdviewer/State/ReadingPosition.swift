import Foundation

/// Where the user left off in one file. Free of PDFKit so it stays Sendable and testable.
struct ReadingPosition: Codable, Equatable, Sendable {
    var pageIndex: Int
    var scaleFactor: Double
    var autoScales: Bool
    /// `PDFDisplayMode` raw value.
    var displayMode: Int
    /// Detects a replaced file; nil means unknown.
    var fileSize: Int64?
    var updatedAt: Date
}
