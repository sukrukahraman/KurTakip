import Foundation

/// Per-environment API settings (ENV-01). The app target builds it from the active configuration's Info.plist values,
/// so library modules never read environment-specific values themselves.
public struct ApiConfig: Sendable, Equatable {
    public let baseURL: URL
    /// `sha256/…` SPKI pins for `baseURL`'s host; empty means pinning is off (HARD-01).
    public let certPins: [String]

    public init(baseURL: URL, certPins: [String]) {
        self.baseURL = baseURL
        self.certPins = certPins
    }

    /// Builds the config from Info.plist strings. Returns nil unless the URL is https (SEC-02).
    /// Pins are comma separated and blanks are ignored.
    public init?(baseURLString: String, certPinsCSV: String) {
        guard let url = URL(string: baseURLString), url.scheme == "https", url.host() != nil else { return nil }
        self.init(
            baseURL: url,
            certPins: certPinsCSV
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        )
    }
}
