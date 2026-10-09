import Foundation
import Testing
@testable import CoreNetwork

@Suite
struct LiveRatesAPITests {
    @Test
    func latest_requestsTryBasedRatesAndDecodesTheDictionary() async throws {
        let config = try #require(ApiConfig(baseURLString: "https://api.frankfurter.dev/v1/", certPinsCSV: ""))
        let body = #"{"amount":1.0,"base":"TRY","date":"2026-10-08","rates":{"EUR":0.01816,"USD":0.02032}}"#
        let transport = HTTPTransport { request in
            let url = try #require(request.url)
            #expect(url.path() == "/v1/latest")
            #expect(url.query() == "base=TRY")
            let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
            return (Data(body.utf8), response)
        }
        let api = LiveRatesAPI(client: APIClient(config: config, transport: transport))

        let dto = try await api.latest()

        #expect(dto == RatesDto(base: "TRY", date: "2026-10-08", rates: ["EUR": 0.01816, "USD": 0.02032]))
    }
}
