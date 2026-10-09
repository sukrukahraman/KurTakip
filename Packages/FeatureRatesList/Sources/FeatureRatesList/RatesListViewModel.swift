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

    /// The cached rates, mapped once per emission instead of on every `uiState` read.
    private struct Snapshot {
        let items: [RateItemUi]
        let updatedOnText: String
    }

    // Inputs. The screen only ever reads `uiState`, which is a pure function of them (ARCH-03).
    private var snapshot: Snapshot?
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
        guard let snapshot else { return .loading }
        if !snapshot.items.isEmpty {
            return .content(RatesListContent(
                rates: matches(snapshot.items),
                updatedOnText: snapshot.updatedOnText,
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
            for try await latest in await repository.observeRates() {
                snapshot = Snapshot(items: latest.map(mapper.map), updatedOnText: mapper.updatedOnText(for: latest))
            }
        } catch {
            observationFailed = true
        }
    }

    /// True when the refresh ran to its end, successfully or with a typed error; false when it was skipped or
    /// cancelled.
    @discardableResult
    func refresh() async -> Bool {
        guard !isRefreshing else { return false }
        isRefreshing = true
        refreshError = nil // COMP-08: a stale error must not show during a new attempt
        defer { isRefreshing = false }
        do {
            refreshError = try await repository.refresh().error
            return true
        } catch {
            return false // cancelled: the screen is gone, leave the state alone
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
        // Only a refresh that finished counts: one cancelled by leaving the screen must run again on return.
        if await refresh() { refreshedAttempt = observeAttempt }
    }
}
