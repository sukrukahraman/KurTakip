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

    @Test
    func appearing_announcesTheMessageToAssistiveTechnology() throws {
        var announced: [String] = []
        let sut = KurTakipBanner(message: "Offline", announce: { announced.append($0) })

        try sut.inspect().find(text: "Offline").callOnAppear()

        #expect(announced == ["Offline"])
    }
}
