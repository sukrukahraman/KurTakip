import Foundation

/// Turns dates into user-facing text. ViewModels and mappers depend on this protocol so tests stay locale-independent
/// (I18N-11); the live implementation follows the user's language and region.
public protocol DateTextFormatting: Sendable {
    func text(for date: Date) -> String
}

/// Formats a calendar day that the data layer stores as UTC midnight (an API quote date). It always reads in GMT, so
/// the
/// day is the same in every time zone: formatting in the local zone showed the previous day west of Greenwich.
public struct LocalizedDateTextFormatter: DateTextFormatting {
    private let locale: Locale

    public init(locale: Locale = .current) {
        self.locale = locale
    }

    public func text(for date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .long, time: .omitted, locale: locale, timeZone: .gmt))
    }
}
