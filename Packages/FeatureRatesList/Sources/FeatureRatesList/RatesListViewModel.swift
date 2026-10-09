import CoreCommon
import CoreModel
import CoreRepository
import Foundation
import Observation

@MainActor
@Observable
final class RatesListViewModel {
    private let repository: any RatesRepository
    private let mapper: RateItemUiMapper

    // Inputs. The screen only ever reads `uiState`, which is a pure function of them (ARCH-03).
    private var rates: [ExchangeRate]?
    private var observationFailed = false
    private var isRefreshing = false
    private var refreshError: AppError?
    private var refreshedAttempt: Int?

    /// The text in the search field; the screen edits it through a binding.
    var query = ""

    /// Bumped by `onRetry()`; the Route restarts `start()` whenever it changes (CONC-07).
    private(set) var observeAttempt = 0

    init(repository: any RatesRepository, mapper: RateItemUiMapper) {
        self.repository = repository
        self.mapper = mapper
    }

    var uiState: RatesListUiState {
        if observationFailed { return .error(.unknown) }
        guard let rates else { return .loading }
        if !rates.isEmpty {
            return .content(RatesListContent(
                rates: matches(rates.map(mapper.map)),
                updatedOnText: mapper.updatedOnText(for: rates),
                isSearching: !trimmedQuery.isEmpty,
                refreshError: refreshError
            ))
        }
        if isRefreshing { return .loading }
        if let refreshError { return .error(refreshError) }
        return .empty
    }

    /// Runs for as long as the screen is visible: observes the cache and refreshes it once per attempt.
    func start() async {
        async let refreshed: Void = refreshOncePerAttempt()
        await observe()
        await refreshed
    }

    func observe() async {
        observationFailed = false
        do {
            for try await latest in await repository.observeRates() { rates = latest }
        } catch {
            observationFailed = true
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        refreshError = nil // COMP-08: a stale error must not show during a new attempt
        defer { isRefreshing = false }
        do {
            refreshError = try await repository.refresh().error
        } catch {
            return // cancelled: the screen is gone, leave the state alone
        }
    }

    func onRetry() {
        observationFailed = false
        observeAttempt += 1
    }

    func onRefreshErrorShown() {
        refreshError = nil
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Matches the code or the localized name, ignoring case and diacritics.
    private func matches(_ items: [RateItemUi]) -> [RateItemUi] {
        guard !trimmedQuery.isEmpty else { return items }
        return items
            .filter {
                $0.code.localizedStandardContains(trimmedQuery) || $0.name.localizedStandardContains(trimmedQuery)
            }
    }

    private func refreshOncePerAttempt() async {
        guard refreshedAttempt != observeAttempt else { return }
        refreshedAttempt = observeAttempt
        await refresh()
    }
}
