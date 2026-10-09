import CoreCommon

/// Deterministic currency text for mapper and ViewModel tests: "name-USD", and "rate-49.5".
public struct FakeCurrencyTextFormatter: CurrencyTextFormatting {
    public init() {}

    public func name(forCode code: String) -> String {
        "name-\(code)"
    }

    public func rateText(_ liraPerUnit: Double) -> String {
        "rate-\(liraPerUnit)"
    }

    public func amountText(_ amount: Double, currencyCode: String, fractionDigits: Int) -> String {
        "amount-\(amount)-\(currencyCode)-\(fractionDigits)"
    }

    /// Plain `Double` parsing, so tests type "1000" and never depend on a locale.
    public func parseAmount(_ text: String) -> Double? {
        Double(text)
    }
}
