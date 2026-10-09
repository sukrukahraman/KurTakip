/// How `safeApiCall` retries transient failures (DATA-03): exponential backoff between a few attempts.
public struct RetryPolicy: Sendable {
    let maxAttempts: Int
    let initialBackoff: Duration
    let maxBackoff: Duration
    let sleep: @Sendable (Duration) async throws -> Void

    /// Tests build a policy that never waits: one attempt, or recorded sleeps (see TEST-07).
    public init(
        maxAttempts: Int,
        initialBackoff: Duration,
        maxBackoff: Duration,
        sleep: @escaping @Sendable (Duration) async throws -> Void
    ) {
        self.maxAttempts = maxAttempts
        self.initialBackoff = initialBackoff
        self.maxBackoff = maxBackoff
        self.sleep = sleep
    }

    /// Three attempts, 0.5 s then 1 s apart (capped at 4 s).
    public static let standard = RetryPolicy(
        maxAttempts: 3,
        initialBackoff: .milliseconds(500),
        maxBackoff: .seconds(4),
        sleep: { try await Task.sleep(for: $0) }
    )
}
