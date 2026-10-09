// coverage:exclude composition root: live(...) wires concrete types and only a running app exercises it

import CoreDatabase
import CoreNetwork

/// The app's repositories, created once by the composition root (`AppContainer`). Add one property per repository
/// and wire its network, database and storage dependencies in `live(...)`. Tests and previews use the fakes from
/// CoreTesting instead, so no feature ever builds a concrete repository.
public struct Repositories: Sendable {
    public let rates: any RatesRepository

    public init(rates: any RatesRepository) {
        self.rates = rates
    }

    public static func live(apiConfig: ApiConfig, database: AppDatabase) -> Repositories {
        let client = APIClient(config: apiConfig)
        return Repositories(
            rates: OfflineFirstRatesRepository(
                api: LiveRatesAPI(client: client),
                store: SwiftDataRateStore(modelContainer: database.container)
            )
        )
    }
}
