import Foundation
import Testing
@testable import CoreCommon

@Suite
struct FormattingTests {
    private let turkish = Locale(identifier: "tr_TR")
    private let english = Locale(identifier: "en_US")

    @Test
    func rateText_usesFourDecimalsInTheLocalesStyle() {
        #expect(LocalizedCurrencyTextFormatter(locale: english).rateText(49.1234567) == "TRY\u{00A0}49.1235")
        #expect(LocalizedCurrencyTextFormatter(locale: turkish).rateText(49.1234567) == "₺49,1235")
    }

    @Test
    func amountText_usesTheRequestedDecimalsInTheGivenCurrency() {
        let formatter = LocalizedCurrencyTextFormatter(locale: english)

        #expect(formatter.amountText(1234.5678, currencyCode: "USD", fractionDigits: 2) == "$1,234.57")
        #expect(formatter.amountText(0.02032, currencyCode: "USD", fractionDigits: 4) == "$0.0203")
    }

    @Test
    func parseAmount_readsTheUsersLocaleAndRejectsText() {
        #expect(LocalizedCurrencyTextFormatter(locale: turkish).parseAmount("1.000,5") == 1000.5)
        #expect(LocalizedCurrencyTextFormatter(locale: english).parseAmount("1,000.5") == 1000.5)
        #expect(LocalizedCurrencyTextFormatter(locale: english).parseAmount("abc") == nil)
        #expect(LocalizedCurrencyTextFormatter(locale: english).parseAmount("") == nil)
    }

    @Test
    func name_isLocalizedAndFallsBackToTheCode() {
        #expect(LocalizedCurrencyTextFormatter(locale: english).name(forCode: "EUR") == "Euro")
        #expect(LocalizedCurrencyTextFormatter(locale: turkish).name(forCode: "USD") == "ABD doları")
        #expect(LocalizedCurrencyTextFormatter(locale: english).name(forCode: "ZZZ") == "ZZZ")
    }

    @Test
    func dateText_isALongDateInTheGivenZone() throws {
        let formatter = LocalizedDateTextFormatter(locale: english, timeZone: try #require(TimeZone(identifier: "UTC")))

        #expect(formatter.text(for: Date(timeIntervalSince1970: 1_791_417_600)) == "October 8, 2026")
    }
}
