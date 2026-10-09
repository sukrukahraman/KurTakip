import SwiftUI
import Testing
import ViewInspector
@testable import CoreDesignSystem

@MainActor
@Suite
struct KurTakipTextFieldTests {
    @Test
    func typing_writesIntoTheBinding() throws {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })
        let sut = KurTakipTextField("Amount", text: binding)

        try sut.inspect().find(ViewType.TextField.self).setInput("12")

        #expect(text == "12")
    }

    @Test
    func showsTheErrorLineOnlyWhenGiven() throws {
        let withError = KurTakipTextField("Amount", text: .constant(""), errorText: "Required")
        let without = KurTakipTextField("Amount", text: .constant(""))

        #expect(try withError.inspect().find(text: "Required").string() == "Required")
        #expect(throws: (any Error).self) { try without.inspect().find(text: "Required") }
    }
}
