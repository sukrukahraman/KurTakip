import Foundation
import Testing
@testable import CoreNetwork

private struct Item: Decodable, Equatable {
    let id: Int
    let createdAt: Date
}

private actor RequestRecorder {
    private(set) var last: URLRequest?

    func record(_ request: URLRequest) { last = request }
}

private func makeClient(
    status: Int = 200,
    body: String = "[]",
    recorder: RequestRecorder = RequestRecorder()
) throws -> APIClient {
    let config = try #require(ApiConfig(baseURLString: "https://api.example.com/v1/", certPinsCSV: ""))
    let transport = HTTPTransport { request in
        await recorder.record(request)
        let url = try #require(request.url)
        let response = try #require(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil))
        return (Data(body.utf8), response)
    }
    return APIClient(config: config, transport: transport)
}

@Suite
struct APIClientTests {
    @Test
    func get_decodesSnakeCaseAndISODates() async throws {
        let client = try makeClient(body: #"[{"id": 7, "created_at": "2024-01-02T03:04:05Z"}]"#)

        let items: [Item] = try await client.get("items")

        #expect(items.map(\.id) == [7])
        #expect(items.first?.createdAt == Date(timeIntervalSince1970: 1_704_164_645))
    }

    @Test
    func get_buildsURLFromBaseAndPathAndQuery() async throws {
        let recorder = RequestRecorder()
        let client = try makeClient(recorder: recorder)

        let _: [Item] = try await client.get("/items", query: [URLQueryItem(name: "page", value: "2")])

        let request = await recorder.last
        #expect(request?.url?.absoluteString == "https://api.example.com/v1/items?page=2")
        #expect(request?.httpMethod == "GET")
    }

    @Test
    func get_onErrorStatus_throwsHTTPError() async throws {
        let client = try makeClient(status: 503)

        await #expect(throws: HTTPError.status(503)) {
            let _: [Item] = try await client.get("items")
        }
    }

    @Test
    func send_usesTheGivenMethod() async throws {
        let recorder = RequestRecorder()
        let client = try makeClient(status: 204, body: "", recorder: recorder)

        try await client.send(method: "DELETE", "items/7")

        #expect(await recorder.last?.httpMethod == "DELETE")
    }
}

@Suite
struct ApiConfigTests {
    @Test
    func rejectsNonHTTPSBaseURL() {
        #expect(ApiConfig(baseURLString: "http://api.example.com/", certPinsCSV: "") == nil)
    }

    @Test
    func parsesPinsAndDropsBlanks() throws {
        let config = try #require(
            ApiConfig(baseURLString: "https://api.example.com/", certPinsCSV: " sha256/a , ,sha256/b")
        )

        #expect(config.certPins == ["sha256/a", "sha256/b"])
    }
}
