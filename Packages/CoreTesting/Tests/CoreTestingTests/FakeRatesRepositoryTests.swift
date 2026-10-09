import CoreCommon
import CoreModel
import Foundation
import Testing
@testable import CoreTesting

@Suite
struct FakeRatesRepositoryTests {
    private let usd = ExchangeRate(code: "USD", tryPerUnit: 50, quotedOn: Date(timeIntervalSince1970: 0))
    private let eur = ExchangeRate(code: "EUR", tryPerUnit: 55, quotedOn: Date(timeIntervalSince1970: 0))

    @Test
    func observe_emitsTheCurrentRatesAndFinishes() async throws {
        let repository = FakeRatesRepository(rates: [usd])
        var iterator = await repository.observeRates().makeAsyncIterator()

        #expect(try await iterator.next() == [usd])
        #expect(try await iterator.next() == nil)
    }

    @Test
    func observe_whenKeptOpen_emitsEveryChange() async throws {
        let repository = FakeRatesRepository(rates: [usd], streamStaysOpen: true)
        var iterator = await repository.observeRates().makeAsyncIterator()
        #expect(try await iterator.next() == [usd])

        repository.emit([usd, eur])

        #expect(try await iterator.next() == [usd, eur])
    }

    @Test
    func observe_afterFailObservation_throwsTheError() async {
        let repository = FakeRatesRepository()
        repository.failObservation(with: CocoaError(.fileReadCorruptFile))
        var iterator = await repository.observeRates().makeAsyncIterator()

        await #expect(throws: CocoaError.self) { try await iterator.next() }
    }

    @Test
    func refresh_countsCallsAndReturnsTheConfiguredResult() async throws {
        let repository = FakeRatesRepository()
        repository.setRefreshResult(.failure(.network))

        let result = try await repository.refresh()

        #expect(result.error == .network)
        #expect(repository.refreshCount == 1)
    }

    @Test
    func refresh_whenSetCancelled_throwsCancellationAndStillCounts() async {
        let repository = FakeRatesRepository()
        repository.setRefreshCancelled(true)

        await #expect(throws: CancellationError.self) { try await repository.refresh() }

        #expect(repository.refreshCount == 1)
    }

    @Test
    func fakeFormatters_areDeterministic() {
        #expect(FakeDateTextFormatter().text(for: Date(timeIntervalSince1970: 7)) == "date-7")
        #expect(FakeCurrencyTextFormatter().name(forCode: "USD") == "name-USD")
        #expect(FakeCurrencyTextFormatter().rateText(49.5) == "rate-49.5")
        #expect(FakeCurrencyTextFormatter()
            .amountText(12.5, currencyCode: "EUR", fractionDigits: 2) == "amount-12.5-EUR-2")
        #expect(FakeCurrencyTextFormatter().parseAmount("12.5") == 12.5)
        #expect(FakeCurrencyTextFormatter().parseAmount("x") == nil)
    }
}
