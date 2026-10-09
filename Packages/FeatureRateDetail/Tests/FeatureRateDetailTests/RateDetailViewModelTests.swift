import CoreCommon
import CoreModel
import CoreTesting
import Foundation
import Testing
@testable import FeatureRateDetail

@MainActor
@Suite
struct RateDetailViewModelTests {
    private let repository = FakeRatesRepository()
    private let usd = ExchangeRate(code: "USD", tryPerUnit: 50, quotedOn: Date(timeIntervalSince1970: 7))
    private let eur = ExchangeRate(code: "EUR", tryPerUnit: 55, quotedOn: Date(timeIntervalSince1970: 7))

    private func makeViewModel(code: String = "USD") -> RateDetailViewModel {
        RateDetailViewModel(code: code, repository: repository, formatter: FakeCurrencyTextFormatter())
    }

    private func content(_ state: RateDetailUiState) -> RateDetailContent? {
        if case .content(let content) = state { content } else { nil }
    }

    @Test
    func givenNothingObservedYet_thenLoading() {
        #expect(makeViewModel().uiState == .loading)
    }

    @Test
    func givenTheRateExists_thenShowsItFormatted() async {
        repository.emit([eur, usd])
        let viewModel = makeViewModel()

        await viewModel.observe()

        let state = content(viewModel.uiState)
        #expect(state?.code == "USD")
        #expect(state?.name == "name-USD")
        #expect(state?.rateText == "rate-50.0")
        #expect(state?.inverseText == "amount-0.02-USD-4")
        #expect(state?.resultText == nil)
        #expect(state?.isAmountInvalid == false)
    }

    @Test
    func givenTheCodeIsNotCached_thenNotFound() async {
        repository.emit([eur])
        let viewModel = makeViewModel()

        await viewModel.observe()

        #expect(viewModel.uiState == .notFound)
    }

    @Test
    func givenAValidAmount_thenConvertsLirasIntoTheCurrency() async {
        repository.emit([usd])
        let viewModel = makeViewModel()
        await viewModel.observe()

        viewModel.amountText = "1000"

        let state = content(viewModel.uiState)
        #expect(state?.resultText == "amount-20.0-USD-2")
        #expect(state?.isAmountInvalid == false)
    }

    @Test
    func givenAnAmountThatIsNotANumber_thenInvalidWithoutResult() async {
        repository.emit([usd])
        let viewModel = makeViewModel()
        await viewModel.observe()

        viewModel.amountText = "abc"

        let state = content(viewModel.uiState)
        #expect(state?.resultText == nil)
        #expect(state?.isAmountInvalid == true)
    }

    @Test
    func givenANegativeAmount_thenInvalid() async {
        repository.emit([usd])
        let viewModel = makeViewModel()
        await viewModel.observe()

        viewModel.amountText = "-5"

        #expect(content(viewModel.uiState)?.isAmountInvalid == true)
    }

    @Test
    func givenOnlyWhitespace_thenNeitherResultNorError() async {
        repository.emit([usd])
        let viewModel = makeViewModel()
        await viewModel.observe()

        viewModel.amountText = "   "

        let state = content(viewModel.uiState)
        #expect(state?.resultText == nil)
        #expect(state?.isAmountInvalid == false)
    }

    @Test
    func givenTheRateDisappears_thenNotFoundAfterwards() async {
        repository.emit([usd])
        let viewModel = makeViewModel()
        await viewModel.observe()
        #expect(content(viewModel.uiState) != nil)

        repository.emit([eur])
        await viewModel.observe()

        #expect(viewModel.uiState == .notFound)
    }

    @Test
    func givenObservingFails_whenRetried_thenRecoversToContent() async {
        repository.failObservation(with: AppError.unknown)
        let viewModel = makeViewModel()
        await viewModel.observe()
        #expect(viewModel.uiState == .error(.unknown))

        repository.failObservation(with: nil)
        repository.emit([usd])
        viewModel.onRetry()
        await viewModel.observe()

        #expect(content(viewModel.uiState)?.code == "USD")
        #expect(viewModel.observeAttempt == 1)
    }
}
