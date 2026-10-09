import Foundation
import Testing
@testable import CoreCommon

@Suite
struct FormattingTests {
    private let turkish = Locale(identifier: "tr_TR")
    private let english = Locale(identifier: "en_US")

    @Test
    func rateText_usesFourDecimalsAndTheLocalesSeparator() {
        #expect(LocalizedCurrencyTextFormatter(locale: english).rateText(49.1234567).contains("49.1235"))
        #expect(LocalizedCurrencyTextFormatter(locale: turkish).rateText(49.1234567).contains("49,1235"))
    }

    @Test
    func amountText_usesTheRequestedDecimals() {
        let formatter = LocalizedCurrencyTextFormatter(locale: english)

        #expect(formatter.amountText(1234.5678, currencyCode: "USD", fractionDigits: 2).contains("1,234.57"))
        #expect(formatter.amountText(0.02032, currencyCode: "USD", fractionDigits: 4).contains("0.0203"))
    }

    @Test
    func parseAmount_acceptsDigitsWithTheLocalesDecimalSeparator() {
        #expect(LocalizedCurrencyTextFormatter(locale: turkish).parseAmount("1000,5") == 1000.5)
        #expect(LocalizedCurrencyTextFormatter(locale: english).parseAmount("1000.5") == 1000.5)
        #expect(LocalizedCurrencyTextFormatter(locale: english).parseAmount("250") == 250)
        #expect(LocalizedCurrencyTextFormatter(locale: turkish).parseAmount(",5") == 0.5)
    }

    @Test
    func parseAmount_rejectsWhatLenientParsingWouldMisread() {
        let turkishFormatter = LocalizedCurrencyTextFormatter(locale: turkish)
        let englishFormatter = LocalizedCurrencyTextFormatter(locale: english)

        #expect(turkishFormatter.parseAmount("1.5") == nil) // read as 1 by lenient parsing
        #expect(turkishFormatter.parseAmount("1.000,5") == nil)
        #expect(englishFormatter.parseAmount("1,5") == nil) // read as 1 by lenient parsing
        #expect(englishFormatter.parseAmount("12abc") == nil)
        #expect(englishFormatter.parseAmount("-5") == nil)
        #expect(englishFormatter.parseAmount("1.2.3") == nil)
        #expect(englishFormatter.parseAmount(".") == nil)
        #expect(englishFormatter.parseAmount("") == nil)
    }

    @Test
    func name_isLocalizedAndFallsBackToTheCode() {
        #expect(LocalizedCurrencyTextFormatter(locale: english).name(forCode: "EUR")
            .localizedCaseInsensitiveContains("euro"))
        #expect(LocalizedCurrencyTextFormatter(locale: turkish).name(forCode: "USD")
            .localizedCaseInsensitiveContains("dolar"))
        #expect(LocalizedCurrencyTextFormatter(locale: english).name(forCode: "ZZZ") == "ZZZ")
    }

    @Test
    func dateText_showsTheStoredCalendarDayWhateverTheTimeZone() {
        // 23:30 UTC on 2026-10-08 is already the 9th in Istanbul and still the 8th in Los Angeles.
        let lateOnTheEighth = Date(timeIntervalSince1970: 1_791_417_600 + 84600)

        let text = LocalizedDateTextFormatter(locale: english).text(for: lateOnTheEighth)

        #expect(text.contains("8"))
        #expect(!text.contains("9"))
        #expect(text.contains("2026"))
    }
}
