import CoreLocalization
import Foundation

/// Expected UI text for tests (TEST-09). Always derive it from the catalog instead of typing the text, so tests
/// pass in whatever language the gate runs in.
public func localizedString(_ key: String.LocalizationValue, table: String) -> String {
    String(localized: key, table: table, bundle: .localization)
}
