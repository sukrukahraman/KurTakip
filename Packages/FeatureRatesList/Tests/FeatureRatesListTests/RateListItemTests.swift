import SwiftUI
import Testing
import ViewInspector
@testable import FeatureRatesList

@MainActor
@Suite
struct RateListItemTests {
    @Test
    func showsCodeNameAndRate() throws {
        let rate = RatesListPreviewData.rates[0]
        let sut = RateListItem(rate: rate)

        #expect(try sut.inspect().find(text: rate.code).string() == rate.code)
        #expect(try sut.inspect().find(text: rate.name).string() == rate.name)
        #expect(try sut.inspect().find(text: rate.rateText).string() == rate.rateText)
    }
}
