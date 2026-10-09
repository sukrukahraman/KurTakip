import CoreModel
import CoreTesting
import Foundation
import Testing
@testable import FeatureRatesList

@Suite
struct RateItemUiMapperTests {
    private let mapper = RateItemUiMapper(
        currencyFormatter: FakeCurrencyTextFormatter(),
        dateFormatter: FakeDateTextFormatter()
    )

    @Test
    func map_namesAndFormatsTheRateThroughTheFormatter() {
        let rate = ExchangeRate(code: "USD", tryPerUnit: 49.5, quotedOn: .distantPast)

        #expect(mapper.map(rate) == RateItemUi(id: "USD", code: "USD", name: "name-USD", rateText: "rate-49.5"))
    }

    @Test
    func updatedOnText_isTheNewestQuoteDay() {
        let older = ExchangeRate(code: "USD", tryPerUnit: 1, quotedOn: Date(timeIntervalSince1970: 5))
        let newer = ExchangeRate(code: "EUR", tryPerUnit: 1, quotedOn: Date(timeIntervalSince1970: 9))

        #expect(mapper.updatedOnText(for: [older, newer]) == "date-9")
    }

    @Test
    func updatedOnText_withoutRates_isEmpty() {
        #expect(mapper.updatedOnText(for: []).isEmpty)
    }
}
