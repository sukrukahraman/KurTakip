import XCTest

/// End-to-end smoke test on a simulator. Run it with the `KurTakip-UITests` scheme (CI-04).
final class LaunchTests: XCTestCase {
    private static let launchTimeout: TimeInterval = 15

    @MainActor
    func testAppLaunchesIntoTheFirstScreen() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: Self.launchTimeout))
    }
}
