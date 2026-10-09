import CoreCommon
import CoreTesting
import Testing
@testable import CoreUI

@Suite
struct AppErrorMessageTests {
    @Test
    func networkAndServerErrorsHaveDifferentText() {
        #expect(AppError.network.message != AppError.server(code: 503).message)
    }

    @Test
    func networkError_usesCommonNetworkText() {
        #expect(AppError.network.message == localizedString("common_error_network", table: "common"))
    }

    @Test
    func unknownError_usesCommonUnknownText() {
        #expect(AppError.unknown.message == localizedString("common_error_unknown", table: "common"))
    }
}
