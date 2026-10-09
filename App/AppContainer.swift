import CoreCommon
import CoreDatabase
import CoreRepository

// coverage:exclude composition root: concrete types are only wired together when the app runs

/// The composition root: the one place that builds concrete implementations and hands them to the features.
/// Features receive protocols only, so tests and previews swap in fakes.
@MainActor
final class AppContainer {
    let dateFormatter: any DateTextFormatting = LocalizedDateTextFormatter()
    let currencyFormatter: any CurrencyTextFormatting = LocalizedCurrencyTextFormatter()
    let repositories: Repositories
    // <skill:container-properties>

    init(configuration: AppConfiguration = .live()) {
        do {
            repositories = .live(apiConfig: configuration.apiConfig, database: try AppDatabase())
        } catch {
            preconditionFailure("Could not open the local database: \(error)")
        }
        // <skill:container-init>
    }
}
