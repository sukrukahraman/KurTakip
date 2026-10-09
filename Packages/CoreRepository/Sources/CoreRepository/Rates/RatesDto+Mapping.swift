import CoreModel
import CoreNetwork
import Foundation

private let quoteBase = "TRY"

extension RatesDto {
    /// The quotes inverted to "lira per unit", sorted by code. Nil when the quote date is malformed or the quotes are
    /// not
    /// based on the lira: inverting another base would store wrong rates without any error.
    /// Currencies without a positive rate are dropped, because inverting them is meaningless.
    func toDomain() -> [ExchangeRate]? {
        guard base == quoteBase else { return nil }
        let quotedOn: Date
        do {
            quotedOn = try Date.ISO8601FormatStyle().year().month().day().parse(date)
        } catch {
            return nil // a malformed day means the whole answer is unusable
        }
        return rates
            .compactMap { code, unitsPerLira in
                guard unitsPerLira > 0 else { return nil }
                return ExchangeRate(code: code, tryPerUnit: 1 / unitsPerLira, quotedOn: quotedOn)
            }
            .sorted { $0.code < $1.code }
    }
}
