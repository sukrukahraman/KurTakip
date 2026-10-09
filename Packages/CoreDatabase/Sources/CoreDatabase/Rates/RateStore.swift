import CoreModel
import Foundation
import SwiftData

/// Local storage for the latest rates. Entities never leave this module: the store speaks domain models.
public protocol RateStore: Sendable {
    /// Emits the current rates right away and again after every write, sorted by currency code.
    func observeAll() async -> AsyncThrowingStream<[ExchangeRate], Error>
    /// Makes the stored set equal to `rates`: new codes are added, known ones updated, vanished ones removed.
    func replaceAll(with rates: [ExchangeRate]) async throws
}

private typealias RateEntity = CurrentSchema.RateEntity

/// SwiftData-backed store. It is the only writer, so notifying observers after each save keeps them current (DATA-06).
@ModelActor
public actor SwiftDataRateStore: RateStore {
    private var observers = ChangeObservers<[ExchangeRate]>()

    public func observeAll() -> AsyncThrowingStream<[ExchangeRate], Error> {
        let id = UUID()
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: [ExchangeRate].self, throwing: Error.self)
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeObserver(id) }
        }
        observers.add(continuation, id: id)
        do {
            continuation.yield(try fetchAll())
        } catch {
            continuation.finish(throwing: error)
        }
        return stream
    }

    public func replaceAll(with rates: [ExchangeRate]) throws {
        let incoming = Dictionary(rates.map { ($0.code, $0) }, uniquingKeysWith: { _, latest in latest })
        let existing = try modelContext.fetch(FetchDescriptor<RateEntity>())
        for entity in existing {
            if let rate = incoming[entity.currencyCode] {
                entity.tryPerUnit = rate.tryPerUnit
                entity.quotedOn = rate.quotedOn
            } else {
                modelContext.delete(entity)
            }
        }
        let known = Set(existing.map(\.currencyCode))
        for rate in incoming.values where !known.contains(rate.code) {
            modelContext.insert(RateEntity(
                currencyCode: rate.code,
                tryPerUnit: rate.tryPerUnit,
                quotedOn: rate.quotedOn
            ))
        }
        try modelContext.save()
        observers.publish(try fetchAll())
    }

    private func removeObserver(_ id: UUID) {
        observers.remove(id: id)
    }

    private func fetchAll() throws -> [ExchangeRate] {
        try modelContext.fetch(FetchDescriptor<RateEntity>(sortBy: [SortDescriptor(\.currencyCode)]))
            .map { ExchangeRate(code: $0.currencyCode, tryPerUnit: $0.tryPerUnit, quotedOn: $0.quotedOn) }
    }
}
