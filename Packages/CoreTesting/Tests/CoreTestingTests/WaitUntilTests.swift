import Testing
@testable import CoreTesting

@MainActor
@Suite
struct WaitUntilTests {
    @Test
    func returnsOnceConditionHolds() async throws {
        var ready = false
        Task { ready = true }

        try await waitUntil { ready }

        #expect(ready)
    }

    @Test
    func throwsWhenConditionNeverHolds() async {
        await #expect(throws: WaitTimeoutError.self) {
            try await waitUntil(timeout: .milliseconds(30)) { false }
        }
    }

    @Test
    func timeoutErrorExplainsItself() {
        #expect(WaitTimeoutError().description.contains("timeout"))
    }
}
