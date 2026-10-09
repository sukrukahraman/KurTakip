import SwiftUI
import Testing
import ViewInspector
@testable import CoreUI

@MainActor
@Suite
struct EmptyAndLoadingStateTests {
    @Test
    func emptyState_showsMessage() throws {
        let sut = EmptyState(message: "Nothing here yet")

        let text = try sut.inspect().find(text: "Nothing here yet").string()

        #expect(text == "Nothing here yet")
    }

    @Test
    func loadingState_showsProgressIndicator() throws {
        let sut = LoadingState()

        _ = try sut.inspect().find(ViewType.ProgressView.self)
    }
}
