/// Wire format of `GET /latest?base=TRY`: how many units of each currency one Turkish lira buys.
/// It never leaves the data layer: repositories map it to the domain model (ARCH-07).
public struct RatesDto: Decodable, Sendable, Equatable {
    public let base: String
    /// Calendar day of the quote, `yyyy-MM-dd`.
    public let date: String
    public let rates: [String: Double]

    public init(base: String, date: String, rates: [String: Double]) {
        self.base = base
        self.date = date
        self.rates = rates
    }
}
