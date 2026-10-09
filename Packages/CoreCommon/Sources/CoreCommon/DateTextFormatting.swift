import Foundation

/// Turns dates into user-facing text. ViewModels and mappers depend on this protocol so tests stay locale-independent
/// (I18N-11); the live implementation follows the user's language and region.
public protocol DateTextFormatting: Sendable {
    func text(for date: Date) -> String
}

public struct LocalizedDateTextFormatter: DateTextFormatting {
    private let locale: Locale
    private let timeZone: TimeZone

    public init(locale: Locale = .current, timeZone: TimeZone = .current) {
        self.locale = locale
        self.timeZone = timeZone
    }

    public func text(for date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .long, time: .omitted, locale: locale, timeZone: timeZone))
    }
}
