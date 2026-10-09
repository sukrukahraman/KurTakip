import CoreCommon
import CoreTesting
import CoreUI
import SwiftUI
import Testing
import ViewInspector
@testable import FeatureRatesList

@MainActor
@Suite
struct RatesListScreenTests {
    private func screen(
        _ state: RatesListUiState,
        query: String = "",
        onRateClick: @escaping (String) -> Void = { _ in },
        onRetry: @escaping () -> Void = {},
        onRefresh: @escaping () async -> Void = {}
    ) -> RatesListScreen {
        RatesListScreen(
            uiState: state,
            query: .constant(query),
            onRateClick: onRateClick,
            onRetry: onRetry,
            onRefresh: onRefresh,
            onRefreshErrorShown: {}
        )
    }

    @Test
    func contentState_showsCodesNamesAndRates() throws {
        let sut = screen(.content(RatesListPreviewData.content))

        let rate = RatesListPreviewData.rates[0]
        #expect(try sut.inspect().find(text: rate.code).string() == rate.code)
        #expect(try sut.inspect().find(text: rate.name).string() == rate.name)
        #expect(try sut.inspect().find(text: rate.rateText).string() == rate.rateText)
    }

    @Test
    func contentState_showsTheCountAndTheUpdatedDay() throws {
        let sut = screen(.content(RatesListPreviewData.content))

        let count = localizedString("ratelist_count \(3)", table: "ratelist")
        let updated = localizedString("ratelist_updated \("8 Oct 2026")", table: "ratelist")
        #expect(try sut.inspect().find(text: count).string() == count)
        #expect(try sut.inspect().find(text: updated).string() == updated)
    }

    @Test
    func contentState_rowTap_passesTheCurrencyCode() throws {
        var tapped: String?
        let sut = screen(.content(RatesListPreviewData.content), onRateClick: { tapped = $0 })

        try sut.inspect().find(button: RatesListPreviewData.rates[1].code).tap()

        #expect(tapped == RatesListPreviewData.rates[1].id)
    }

    @Test
    func searchWithoutMatches_showsTheNoMatchMessage() throws {
        let noMatch = RatesListContent(rates: [], updatedOnText: "", isSearching: true, refreshError: nil)
        let sut = screen(.content(noMatch), query: "zzz")

        let message = localizedString("ratelist_search_empty", table: "ratelist")

        #expect(try sut.inspect().find(text: message).string() == message)
    }

    @Test
    func refreshError_showsTheBannerOverTheContent() throws {
        let content = RatesListContent(
            rates: RatesListPreviewData.rates,
            updatedOnText: "8 Oct 2026",
            isSearching: false,
            refreshError: .network
        )
        let sut = screen(.content(content))

        let message = localizedString("ratelist_refresh_failed", table: "ratelist")

        #expect(try sut.inspect().find(text: message).string() == message)
    }

    @Test
    func errorState_retryTap_invokesCallback() throws {
        var retries = 0
        let sut = screen(.error(.network), onRetry: { retries += 1 })

        try sut.inspect().find(button: localizedString("common_retry", table: "common")).tap()

        #expect(retries == 1)
        #expect(try sut.inspect().find(text: AppError.network.message).string() == AppError.network.message)
    }

    @Test
    func emptyState_showsMessageInsideTheRefreshableList() async throws {
        var refreshes = 0
        let sut = screen(.empty, onRefresh: { refreshes += 1 })

        let message = localizedString("ratelist_empty", table: "ratelist")
        #expect(try sut.inspect().find(text: message).string() == message)
        try await sut.inspect().find(ViewType.List.self).callRefreshable()

        #expect(refreshes == 1) // ERR-07: pulling down on the empty state still refreshes
    }

    @Test
    func loadingState_showsProgress() throws {
        _ = try screen(.loading).inspect().find(ViewType.ProgressView.self)
    }
}
