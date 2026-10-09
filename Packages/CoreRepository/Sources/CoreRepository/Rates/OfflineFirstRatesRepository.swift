import CoreCommon
import CoreDatabase
import CoreModel
import CoreNetwork

struct OfflineFirstRatesRepository: RatesRepository {
    let api: any RatesAPI
    let store: any RateStore
    var retry: RetryPolicy = .standard

    func observeRates() async -> AsyncThrowingStream<[ExchangeRate], Error> {
        await store.observeAll()
    }

    func refresh() async throws(CancellationError) -> AppResult<Void> {
        let api = api
        switch try await safeApiCall(retry: retry, { try await api.latest() }) {
        case .success(let dto):
            // An unreadable or empty answer must not wipe a good cache.
            guard let rates = dto.toDomain(), !rates.isEmpty else { return .failure(.unknown) }
            do {
                try await store.replaceAll(with: rates)
                return .success(())
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // ERR-08: a full disk or a corrupt store is a typed failure, never a crash.
                return .failure(.unknown)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
}
