import Foundation
import Testing
@testable import CoreLocalization

@Suite
struct BundleLocalizationTests {
    @Test
    func localizationBundleResolvesCommonKeys() {
        let retry = String(localized: "common_retry", table: "common", bundle: .localization)

        #expect(retry != "common_retry")
        #expect(!retry.isEmpty)
    }
}
