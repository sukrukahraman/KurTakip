import CoreCommon
import CoreDatabase
import CoreModel
import CoreNetwork
import Foundation
import Testing
@testable import CoreRepository

/// One attempt and no waiting. CoreTesting cannot host this: it depends on CoreRepository, so a package cycle.
private let noRetry = RetryPolicy(maxAttempts: 1, initialBackoff: .zero, maxBackoff: .zero, sleep: { _ in })

private struct FakeRatesAPI: RatesAPI {
    var result: Result<RatesDto, any Error>

    func latest() async throws -> RatesDto {
        try result.get()
    }
}

private actor FakeRateStore: RateStore {
    private(set) var saved: [ExchangeRate] = []
    private let replaceError: (any Error)?

    init(saved: [ExchangeRate] = [], replaceError: (any Error)? = nil) {
        self.saved = saved
        self.replaceError = replaceError
    }

    func observeAll() -> AsyncThrowingStream<[ExchangeRate], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(saved)
            continuation.finish()
        }
    }

    func replaceAll(with rates: [ExchangeRate]) throws {
        if let replaceError { throw replaceError }
        saved = rates
    }
}

@Suite
struct OfflineFirstRatesRepositoryTests {
    private let dto = RatesDto(base: "TRY", date: "2026-10-08", rates: ["USD": 0.02])
    private let cached = ExchangeRate(code: "EUR", tryPerUnit: 55, quotedOn: Date(timeIntervalSince1970: 0))

    private func repository(
        api: Result<RatesDto, any Error>,
        store: FakeRateStore = FakeRateStore()
    ) -> OfflineFirstRatesRepository {
        OfflineFirstRatesRepository(api: FakeRatesAPI(result: api), store: store, retry: noRetry)
    }

    @Test
    func refresh_storesTheMappedRates() async throws {
        let store = FakeRateStore()

        let result = try await repository(api: .success(dto), store: store).refresh()

        #expect(result.error == nil)
        #expect(await store.saved.map(\.code) == ["USD"])
    }

    @Test
    func refresh_networkFailure_isTypedAndLeavesTheCacheUntouched() async throws {
        let store = FakeRateStore(saved: [cached])

        let result = try await repository(api: .failure(URLError(.notConnectedToInternet)), store: store).refresh()

        #expect(result.error == .network)
        #expect(await store.saved == [cached])
    }

    @Test
    func refresh_emptyAnswer_isUnknownAndKeepsTheCache() async throws {
        let store = FakeRateStore(saved: [cached])
        let empty = RatesDto(base: "TRY", date: "2026-10-08", rates: [:])

        let result = try await repository(api: .success(empty), store: store).refresh()

        #expect(result.error == .unknown)
        #expect(await store.saved == [cached])
    }

    @Test
    func refresh_malformedDate_isUnknown() async throws {
        let broken = RatesDto(base: "TRY", date: "soon", rates: ["USD": 0.02])

        #expect(try await repository(api: .success(broken)).refresh().error == .unknown)
    }

    @Test
    func refresh_storeFailure_isTypedNotThrown() async throws {
        let store = FakeRateStore(replaceError: CocoaError(.fileWriteOutOfSpace))

        #expect(try await repository(api: .success(dto), store: store).refresh().error == .unknown)
    }

    @Test
    func refresh_cancelledStore_rethrowsCancellation() async {
        let store = FakeRateStore(replaceError: CancellationError())

        await #expect(throws: CancellationError.self) {
            try await repository(api: .success(dto), store: store).refresh()
        }
    }

    @Test
    func observeRates_emitsWhatTheStoreHolds() async throws {
        let store = FakeRateStore(saved: [cached])
        var iterator = await repository(api: .success(dto), store: store).observeRates().makeAsyncIterator()

        #expect(try await iterator.next() == [cached])
    }
}
