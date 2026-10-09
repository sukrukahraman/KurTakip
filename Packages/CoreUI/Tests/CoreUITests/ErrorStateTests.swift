import CoreTesting
import SwiftUI
import Testing
import ViewInspector
@testable import CoreUI

@MainActor
@Suite
struct ErrorStateTests {
    @Test
    func showsMessage() throws {
        let sut = ErrorState(message: "Boom") {}

        let text = try sut.inspect().find(text: "Boom").string()

        #expect(text == "Boom")
    }

    @Test
    func retryTap_invokesCallback() throws {
        var retries = 0
        let sut = ErrorState(message: "Boom") { retries += 1 }

        try sut.inspect().find(button: localizedString("common_retry", table: "common")).tap()

        #expect(retries == 1)
    }
}
