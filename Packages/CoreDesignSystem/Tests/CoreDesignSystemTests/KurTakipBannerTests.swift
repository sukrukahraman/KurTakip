import SwiftUI
import Testing
import ViewInspector
@testable import CoreDesignSystem

@MainActor
@Suite
struct KurTakipBannerTests {
    @Test
    func showsTheMessage() throws {
        let sut = KurTakipBanner(message: "Offline")

        #expect(try sut.inspect().find(text: "Offline").string() == "Offline")
    }
}
