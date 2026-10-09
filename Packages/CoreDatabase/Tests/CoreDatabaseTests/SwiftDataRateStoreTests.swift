import CoreModel
import Foundation
import Testing
@testable import CoreDatabase

@Suite
struct SwiftDataRateStoreTests {
    private let day = Date(timeIntervalSince1970: 1_000_000)

    private func makeStore() throws -> SwiftDataRateStore {
        SwiftDataRateStore(modelContainer: try AppDatabase(inMemory: true).container)
    }

    private func rate(_ code: String, _ value: Double) -> ExchangeRate {
        ExchangeRate(code: code, tryPerUnit: value, quotedOn: day)
    }

    @Test
    func observe_emitsStoredRatesSortedByCode() async throws {
        let store = try makeStore()
        try await store.replaceAll(with: [rate("USD", 49), rate("EUR", 55)])

        var iterator = await store.observeAll().makeAsyncIterator()

        #expect(try await iterator.next()?.map(\.code) == ["EUR", "USD"])
    }

    @Test
    func replaceAll_updatesKnownAddsNewAndRemovesVanishedCodes() async throws {
        let store = try makeStore()
        try await store.replaceAll(with: [rate("USD", 49), rate("EUR", 55), rate("GBP", 64)])

        try await store.replaceAll(with: [rate("USD", 50), rate("JPY", 0.33)])

        var iterator = await store.observeAll().makeAsyncIterator()
        #expect(try await iterator.next() == [rate("JPY", 0.33), rate("USD", 50)])
    }

    @Test
    func observer_isNotifiedAfterEveryWrite() async throws {
        let store = try makeStore()
        var iterator = await store.observeAll().makeAsyncIterator()
        #expect(try await iterator.next() == [])

        try await store.replaceAll(with: [rate("USD", 49)])

        #expect(try await iterator.next() == [rate("USD", 49)])
    }
}
