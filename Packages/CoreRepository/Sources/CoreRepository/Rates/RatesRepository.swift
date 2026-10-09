import CoreCommon
import CoreModel

/// What features see of the exchange-rate data (ARCH-04). The local database is the source of truth and the network
/// only refreshes it (DATA-06).
public protocol RatesRepository: Sendable {
    /// Emits the cached rates immediately and again after every change. Throws when reading the cache fails.
    func observeRates() async -> AsyncThrowingStream<[ExchangeRate], Error>

    /// Fetches the latest rates into the cache. Only cancellation is thrown; every other failure is a typed result.
    func refresh() async throws(CancellationError) -> AppResult<Void>
}
