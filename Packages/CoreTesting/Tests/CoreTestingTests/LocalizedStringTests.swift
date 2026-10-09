import Testing
@testable import CoreTesting

@Suite
struct LocalizedStringTests {
    @Test
    func localizedString_resolvesAKeyFromTheCatalog() {
        let text = localizedString("common_retry", table: "common")

        #expect(text != "common_retry")
        #expect(!text.isEmpty)
    }

    @Test
    func localizedString_ofAnUnknownKey_isTheKeyItself() {
        #expect(localizedString("common_does_not_exist", table: "common") == "common_does_not_exist")
    }
}
