import SwiftUI

@main
struct KurTakipApp: App {
    /// Unit tests are hosted by the app; they must not open the real database or talk to the network.
    private let isHostingUnitTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    var body: some Scene {
        WindowGroup {
            if isHostingUnitTests {
                Color.clear
            } else {
                AppRoot()
            }
        }
    }
}
