import Foundation
import Testing
@testable import KurTakip

@Suite
struct AppConfigurationTests {
    @Test
    func buildsApiConfigFromInfoValues() throws {
        let info: [String: Any] = ["API_BASE_URL": "https://api.example.com/v1/", "API_CERT_PINS": "sha256/a,sha256/b"]

        let configuration = try #require(AppConfiguration(info: info))

        #expect(configuration.apiConfig.baseURL.host() == "api.example.com")
        #expect(configuration.apiConfig.certPins == ["sha256/a", "sha256/b"])
    }

    @Test
    func missingBaseURL_isRejected() {
        #expect(AppConfiguration(info: [:]) == nil)
    }

    @Test
    func cleartextBaseURL_isRejected() {
        #expect(AppConfiguration(info: ["API_BASE_URL": "http://api.example.com/"]) == nil)
    }

    @Test
    func theRunningBuild_hasAValidConfiguration() {
        _ = AppConfiguration.live() // would crash at launch otherwise (ENV-01)
    }
}
