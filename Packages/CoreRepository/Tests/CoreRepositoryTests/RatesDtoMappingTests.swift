import CoreModel
import CoreNetwork
import Foundation
import Testing
@testable import CoreRepository

@Suite
struct RatesDtoMappingTests {
    @Test
    func toDomain_invertsEachQuoteIntoLiraPerUnitSortedByCode() throws {
        let dto = RatesDto(base: "TRY", date: "2026-10-08", rates: ["USD": 0.02, "EUR": 0.0125])

        let rates = try #require(dto.toDomain())

        #expect(rates.map(\.code) == ["EUR", "USD"])
        #expect(rates.map(\.tryPerUnit) == [80, 50])
    }

    @Test
    func toDomain_readsTheQuoteDateAsAUtcCalendarDay() throws {
        let dto = RatesDto(base: "TRY", date: "2026-10-08", rates: ["USD": 0.02])

        let rate = try #require(dto.toDomain()?.first)

        #expect(rate.quotedOn == Date(timeIntervalSince1970: 1_791_417_600))
    }

    @Test
    func toDomain_dropsCurrenciesWithoutAPositiveRate() throws {
        let dto = RatesDto(base: "TRY", date: "2026-10-08", rates: ["USD": 0.02, "XXX": 0, "YYY": -1])

        #expect(try #require(dto.toDomain()).map(\.code) == ["USD"])
    }

    @Test
    func toDomain_malformedDate_isNil() {
        #expect(RatesDto(base: "TRY", date: "yesterday", rates: ["USD": 0.02]).toDomain() == nil)
    }
}
