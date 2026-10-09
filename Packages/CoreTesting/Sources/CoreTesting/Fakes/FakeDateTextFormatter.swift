import CoreCommon
import Foundation

/// Deterministic date text for mapper and ViewModel tests: "date-<seconds since 1970>".
public struct FakeDateTextFormatter: DateTextFormatting {
    public init() {}

    public func text(for date: Date) -> String {
        "date-\(Int(date.timeIntervalSince1970))"
    }
}
