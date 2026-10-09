import CoreCommon
import Foundation
import Testing
@testable import CoreNetwork

/// Collects the backoff durations a test run asked for, without waiting.
private actor SleepRecorder {
    private(set) var durations: [Duration] = []

    func record(_ duration: Duration) { durations.append(duration) }
}

/// Three attempts like the real policy, but sleeping is recorded instead of waited for.
private func recordingPolicy(_ recorder: SleepRecorder) -> RetryPolicy {
    RetryPolicy(
        maxAttempts: 3,
        initialBackoff: .milliseconds(500),
        maxBackoff: .seconds(4),
        sleep: { await recorder.record($0) }
    )
}

private let instantRetries = RetryPolicy(maxAttempts: 3, initialBackoff: .zero, maxBackoff: .zero, sleep: { _ in })

private actor CallCounter {
    private(set) var count = 0

    func next() -> Int {
        count += 1
        return count
    }
}

@Suite
struct SafeApiCallTests {
    @Test
    func success_returnsValueWithoutSleeping() async throws {
        let recorder = SleepRecorder()

        let result = try await safeApiCall(retry: recordingPolicy(recorder)) { 42 }

        #expect(result == .success(42))
        #expect(await recorder.durations.isEmpty)
    }

    @Test
    func transientNetworkFailure_isRetriedWithDoublingBackoff() async throws {
        let recorder = SleepRecorder()
        let counter = CallCounter()

        let result = try await safeApiCall(retry: recordingPolicy(recorder)) {
            if await counter.next() < 3 { throw URLError(.notConnectedToInternet) }
            return "ok"
        }

        #expect(result == .success("ok"))
        #expect(await recorder.durations == [.milliseconds(500), .seconds(1)])
    }

    @Test
    func exhaustedRetries_returnNetworkError() async throws {
        let counter = CallCounter()

        let result: AppResult<Int> = try await safeApiCall(retry: instantRetries) {
            _ = await counter.next()
            throw URLError(.timedOut)
        }

        #expect(result == .failure(.network))
        #expect(await counter.count == 3)
    }

    @Test
    func serverError5xx_isRetriedAndMapped() async throws {
        let counter = CallCounter()

        let result: AppResult<Int> = try await safeApiCall(retry: instantRetries) {
            _ = await counter.next()
            throw HTTPError.status(503)
        }

        #expect(result == .failure(.server(code: 503)))
        #expect(await counter.count == 3)
    }

    @Test
    func clientError4xx_failsFast() async throws {
        let counter = CallCounter()

        let result: AppResult<Int> = try await safeApiCall(retry: instantRetries) {
            _ = await counter.next()
            throw HTTPError.status(404)
        }

        #expect(result == .failure(.server(code: 404)))
        #expect(await counter.count == 1)
    }

    @Test
    func decodingError_failsFastAsUnknown() async throws {
        let counter = CallCounter()

        let result: AppResult<Int> = try await safeApiCall(retry: instantRetries) {
            _ = await counter.next()
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad"))
        }

        #expect(result == .failure(.unknown))
        #expect(await counter.count == 1)
    }

    @Test
    func rejectedCertificatePin_isNotRetriedAndIsNotANetworkError() async throws {
        let counter = CallCounter()

        let result: AppResult<Int> = try await safeApiCall(retry: instantRetries) {
            _ = await counter.next()
            throw URLError(.cancelled)
        }

        #expect(result == .failure(.unknown))
        #expect(await counter.count == 1)
    }

    @Test
    func cancellation_isRethrown() async {
        let task = Task {
            try await safeApiCall(retry: instantRetries) { () async throws -> Int in
                try await Task.sleep(for: .seconds(30))
                return 1
            }
        }
        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
    }
}
