import Foundation
import Testing
@testable import FeatureRateDetail

@Suite
struct RateDetailKeyTests {
    @Test
    func codable_roundTripsSoTheBackStackCanBeRestored() throws {
        let key = RateDetailKey(code: "USD")

        let decoded = try JSONDecoder().decode(RateDetailKey.self, from: JSONEncoder().encode(key))

        #expect(decoded == key)
    }
}
