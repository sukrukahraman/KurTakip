import Foundation

public struct WaitTimeoutError: Error, CustomStringConvertible {
    public let description = "Condition was not met before the timeout"
}

/// Yields to the scheduler until `condition` holds. Prefer driving finite fake streams to completion; use this
/// only for state that changes from a background task (TEST-07).
@MainActor
public func waitUntil(
    timeout: Duration = .seconds(2),
    _ condition: @MainActor () -> Bool
) async throws {
    let deadline = ContinuousClock.now.advanced(by: timeout)
    while !condition() {
        guard ContinuousClock.now < deadline else { throw WaitTimeoutError() }
        try await Task.sleep(for: .milliseconds(5))
    }
}
