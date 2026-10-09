import SwiftUI
import Testing
import ViewInspector
@testable import CoreDesignSystem

@MainActor
@Suite
struct KurTakipButtonTests {
    @Test
    func tap_invokesAction() throws {
        var taps = 0
        let sut = KurTakipButton("Save") { taps += 1 }

        try sut.inspect().find(button: "Save").tap()

        #expect(taps == 1)
    }

    @Test
    func showsTitle() throws {
        let sut = KurTakipButton("Save") {}

        let title = try sut.inspect().find(text: "Save").string()

        #expect(title == "Save")
    }
}
