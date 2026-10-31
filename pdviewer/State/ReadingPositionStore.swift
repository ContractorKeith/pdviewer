import Foundation
import Observation

/// Remembers where the user left off in each file (page, zoom, display mode)
/// and restores it on reopen. App-wide singleton; keyed by file.
@MainActor
@Observable
final class ReadingPositionStore {
    static let shared = ReadingPositionStore()

    /// Apply the saved position for `url` to `controller`, if one exists.
    func restore(for url: URL?, into controller: ReaderController) {
        // Implemented in milestone 5.
    }

    /// Record the controller's current position for `url`.
    func save(for url: URL?, from controller: ReaderController) {
        // Implemented in milestone 5.
    }
}
