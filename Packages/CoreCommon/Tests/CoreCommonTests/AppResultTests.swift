import Testing
@testable import CoreCommon

@Suite
struct AppResultTests {
    @Test
    func error_ofASuccess_isNil() {
        let result: AppResult<Int> = .success(1)

        #expect(result.error == nil)
    }

    @Test
    func error_ofAFailure_isTheTypedError() {
        let result: AppResult<Int> = .failure(.server(code: 503))

        #expect(result.error == .server(code: 503))
    }

    @Test
    func error_worksForVoidResults() {
        let result: AppResult<Void> = .failure(.network)

        #expect(result.error == .network)
    }
}
