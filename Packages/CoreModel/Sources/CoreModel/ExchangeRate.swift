import Foundation

/// The value of one unit of a foreign currency in Turkish lira, as quoted on a given day.
public struct ExchangeRate: Sendable, Equatable, Identifiable {
    public let code: String
    public let tryPerUnit: Double
    public let quotedOn: Date

    public var id: String { code }

    public init(code: String, tryPerUnit: Double, quotedOn: Date) {
        self.code = code
        self.tryPerUnit = tryPerUnit
        self.quotedOn = quotedOn
    }
}
