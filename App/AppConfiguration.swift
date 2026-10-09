import CoreNetwork
import Foundation

/// This build's environment values. The active xcconfig fills Info.plist, so staging and production builds differ
/// without any runtime `if environment == …` (ENV-01).
struct AppConfiguration {
    let apiConfig: ApiConfig

    /// Nil when a value is missing or the API URL is not https; `live()` turns that into a launch-time crash.
    init?(info: [String: Any]) {
        guard let baseURL = info["API_BASE_URL"] as? String,
              let apiConfig = ApiConfig(baseURLString: baseURL, certPinsCSV: info["API_CERT_PINS"] as? String ?? "")
        else { return nil }
        self.apiConfig = apiConfig
    }

    static func live(bundle: Bundle = .main) -> AppConfiguration {
        guard let configuration = AppConfiguration(info: bundle.infoDictionary ?? [:]) else {
            preconditionFailure("API_BASE_URL in Info.plist must be an https URL; check Config/<Environment>.xcconfig")
        }
        return configuration
    }
}
