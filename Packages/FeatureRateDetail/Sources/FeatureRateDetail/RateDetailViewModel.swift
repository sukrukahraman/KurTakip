import CoreCommon
import CoreModel
import CoreRepository
import Foundation
import Observation

private let inverseFractionDigits = 4
private let resultFractionDigits = 2

@MainActor
@Observable
final class RateDetailViewModel {
    private enum Lookup {
        case pending
        case found(ExchangeRate)
        case missing
    }

    private let code: String
    private let repository: any RatesRepository
    private let formatter: any CurrencyTextFormatting

    // Inputs. The screen only ever reads `uiState`, which is a pure function of them (ARCH-03).
    private var lookup = Lookup.pending
    private var observationFailed = false

    /// The lira amount typed by the user; the screen edits it through a binding.
    var amountText = ""

    /// Bumped by `onRetry()`; the Route restarts `observe()` whenever it changes (CONC-07).
    private(set) var observeAttempt = 0

    /// The code arrives through the initializer, so tests construct the ViewModel directly (TEST-09).
    init(code: String, repository: any RatesRepository, formatter: any CurrencyTextFormatting) {
        self.code = code
        self.repository = repository
        self.formatter = formatter
    }

    var uiState: RateDetailUiState {
        if observationFailed { return .error(.unknown) }
        switch lookup {
        case .pending: return .loading
        case .missing: return .notFound
        case .found(let rate): return .content(content(for: rate))
        }
    }

    func observe() async {
        observationFailed = false
        do {
            for try await rates in await repository.observeRates() {
                lookup = rates.first { $0.code == code }.map(Lookup.found) ?? .missing
            }
        } catch {
            observationFailed = true
        }
    }

    func onRetry() {
        observationFailed = false
        observeAttempt += 1
    }

    private func content(for rate: ExchangeRate) -> RateDetailContent {
        let trimmed = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        let liras = trimmed.isEmpty ? nil : formatter.parseAmount(trimmed).flatMap { $0 >= 0 ? $0 : nil }
        return RateDetailContent(
            code: rate.code,
            name: formatter.name(forCode: rate.code),
            rateText: formatter.rateText(rate.tryPerUnit),
            inverseText: formatter.amountText(
                1 / rate.tryPerUnit,
                currencyCode: rate.code,
                fractionDigits: inverseFractionDigits
            ),
            resultText: liras.map { liras in
                let converted = liras / rate.tryPerUnit
                return formatter.amountText(converted, currencyCode: rate.code, fractionDigits: resultFractionDigits)
            },
            isAmountInvalid: !trimmed.isEmpty && liras == nil
        )
    }
}
