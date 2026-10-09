import Foundation

private let rateFractionDigits = 4

/// Turns currency codes and amounts into user-facing text (I18N-11). Mappers and ViewModels depend on this protocol so
/// tests stay locale-independent; the live implementation follows the user's language and region.
public protocol CurrencyTextFormatting: Sendable {
    /// The currency's name in the user's language, or the code itself when the system does not know it.
    func name(forCode code: String) -> String
    /// A quote in lira, with the precision exchange rates are conventionally shown in.
    func rateText(_ liraPerUnit: Double) -> String
    /// An amount in the given currency with a fixed number of decimals.
    func amountText(_ amount: Double, currencyCode: String, fractionDigits: Int) -> String
    /// The number a user typed, read in the user's locale; nil when it is not a number.
    func parseAmount(_ text: String) -> Double?
}

public struct LocalizedCurrencyTextFormatter: CurrencyTextFormatting {
    private let locale: Locale

    public init(locale: Locale = .current) {
        self.locale = locale
    }

    public func name(forCode code: String) -> String {
        locale.localizedString(forCurrencyCode: code) ?? code
    }

    public func rateText(_ liraPerUnit: Double) -> String {
        text(liraPerUnit, currencyCode: "TRY", fractionDigits: rateFractionDigits)
    }

    public func amountText(_ amount: Double, currencyCode: String, fractionDigits: Int) -> String {
        text(amount, currencyCode: currencyCode, fractionDigits: fractionDigits)
    }

    public func parseAmount(_ text: String) -> Double? {
        do {
            return NSDecimalNumber(decimal: try Decimal(text, format: .number.locale(locale))).doubleValue
        } catch {
            return nil // not a number in the user's locale
        }
    }

    private func text(_ value: Double, currencyCode: String, fractionDigits: Int) -> String {
        value.formatted(
            .currency(code: currencyCode).locale(locale).precision(.fractionLength(fractionDigits))
        )
    }
}
