import CoreCommon
import CoreModel
import CoreTesting
import Foundation
import Testing
@testable import FeatureRatesList

@MainActor
@Suite
struct RatesListViewModelTests {
    private let repository = FakeRatesRepository()
    private let usd = ExchangeRate(code: "USD", tryPerUnit: 49.5, quotedOn: Date(timeIntervalSince1970: 7))
    private let eur = ExchangeRate(code: "EUR", tryPerUnit: 55, quotedOn: Date(timeIntervalSince1970: 7))

    private func makeViewModel() -> RatesListViewModel {
        RatesListViewModel(
            repository: repository,
            mapper: RateItemUiMapper(
                currencyFormatter: FakeCurrencyTextFormatter(),
                dateFormatter: FakeDateTextFormatter()
            )
        )
    }

    private func content(_ state: RatesListUiState) -> RatesListContent? {
        if case .content(let content) = state { content } else { nil }
    }

    @Test
    func givenNothingObservedYet_thenLoading() {
        #expect(makeViewModel().uiState == .loading)
    }

    @Test
    func givenCachedRates_whenObserved_thenShowsMappedContent() async {
        repository.emit([usd, eur])
        let viewModel = makeViewModel()

        await viewModel.observe()

        let state = content(viewModel.uiState)
        #expect(state?.rates.map(\.code) == ["USD", "EUR"])
        #expect(state?.rates.first?.rateText == "rate-49.5")
        #expect(state?.updatedOnText == "date-7")
        #expect(state?.isSearching == false)
        #expect(state?.refreshError == nil)
    }

    @Test
    func givenNoRatesAndRefreshSucceeds_thenEmpty() async {
        let viewModel = makeViewModel()
        await viewModel.observe()

        await viewModel.refresh()

        #expect(viewModel.uiState == .empty)
    }

    @Test
    func givenNoRatesAndRefreshFails_thenErrorWithTheTypedCause() async {
        repository.setRefreshResult(.failure(.network))
        let viewModel = makeViewModel()
        await viewModel.observe()

        await viewModel.refresh()

        #expect(viewModel.uiState == .error(.network))
    }

    @Test
    func givenCachedRatesAndRefreshFails_thenKeepsContentWithRefreshError() async {
        repository.emit([usd])
        repository.setRefreshResult(.failure(.server(code: 503)))
        let viewModel = makeViewModel()
        await viewModel.observe()

        await viewModel.refresh()

        let state = content(viewModel.uiState)
        #expect(state?.rates.count == 1)
        #expect(state?.refreshError == .server(code: 503))
    }

    @Test
    func whenRefreshErrorShown_thenItIsCleared() async {
        repository.emit([usd])
        repository.setRefreshResult(.failure(.network))
        let viewModel = makeViewModel()
        await viewModel.observe()
        await viewModel.refresh()

        viewModel.onRefreshErrorShown()

        #expect(content(viewModel.uiState)?.refreshError == nil)
    }

    @Test
    func givenObservingTheCacheFails_whenRetried_thenRecoversToContent() async {
        repository.failObservation(with: AppError.unknown)
        let viewModel = makeViewModel()
        await viewModel.observe()
        #expect(viewModel.uiState == .error(.unknown))

        repository.failObservation(with: nil)
        repository.emit([usd])
        viewModel.onRetry()
        await viewModel.observe()

        #expect(content(viewModel.uiState)?.rates.count == 1)
        #expect(viewModel.observeAttempt == 1)
    }

    @Test
    func start_refreshesOncePerAttempt() async {
        let viewModel = makeViewModel()

        await viewModel.start()
        await viewModel.start()
        #expect(repository.refreshCount == 1)

        viewModel.onRetry()
        await viewModel.start()
        #expect(repository.refreshCount == 2)
    }

    @Test
    func start_afterACancelledRefresh_refreshesAgainOnTheNextStart() async {
        repository.emit([usd])
        repository.setRefreshCancelled(true)
        let viewModel = makeViewModel()
        await viewModel.start()
        #expect(repository.refreshCount == 1)

        repository.setRefreshCancelled(false)
        await viewModel.start()

        #expect(repository.refreshCount == 2)
        await viewModel.start()
        #expect(repository.refreshCount == 2) // finished now: no third refresh for this attempt
    }

    @Test
    func givenAQuery_thenOnlyMatchingCodesOrNamesRemain() async {
        repository.emit([usd, eur])
        let viewModel = makeViewModel()
        await viewModel.observe()

        viewModel.query = "eu"

        let state = content(viewModel.uiState)
        #expect(state?.rates.map(\.code) == ["EUR"])
        #expect(state?.isSearching == true)
        #expect(viewModel.query == "eu")
    }

    @Test
    func givenAQueryMatchingTheName_thenTheRateIsKept() async {
        repository.emit([usd, eur])
        let viewModel = makeViewModel()
        await viewModel.observe()

        viewModel.query = "name-usd"

        #expect(content(viewModel.uiState)?.rates.map(\.code) == ["USD"])
    }

    @Test
    func givenAQueryMatchingNothing_thenContentIsEmptyButSearching() async {
        repository.emit([usd])
        let viewModel = makeViewModel()
        await viewModel.observe()

        viewModel.query = "zzz"

        let state = content(viewModel.uiState)
        #expect(state?.rates.isEmpty == true)
        #expect(state?.isSearching == true)
    }

    @Test
    func givenOnlyWhitespaceQuery_thenNothingIsFiltered() async {
        repository.emit([usd, eur])
        let viewModel = makeViewModel()
        await viewModel.observe()

        viewModel.query = "   "

        let state = content(viewModel.uiState)
        #expect(state?.rates.count == 2)
        #expect(state?.isSearching == false)
    }
}
