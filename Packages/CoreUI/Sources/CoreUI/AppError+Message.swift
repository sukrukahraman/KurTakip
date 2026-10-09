import CoreCommon
import CoreLocalization
import Foundation

public extension AppError {
    /// The one place that turns a typed error into user-facing text (ERR-01).
    var message: String {
        switch self {
        case .network:
            String(localized: "common_error_network", table: "common", bundle: .localization)
        case .server:
            String(localized: "common_error_server", table: "common", bundle: .localization)
        case .unknown:
            String(localized: "common_error_unknown", table: "common", bundle: .localization)
        }
    }
}
