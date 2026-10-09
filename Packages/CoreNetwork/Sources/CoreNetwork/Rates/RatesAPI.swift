import Foundation

public protocol RatesAPI: Sendable {
    func latest() async throws -> RatesDto
}

public struct LiveRatesAPI: RatesAPI {
    private let client: APIClient

    public init(client: APIClient) {
        self.client = client
    }

    public func latest() async throws -> RatesDto {
        try await client.get("latest", query: [URLQueryItem(name: "base", value: "TRY")])
    }
}
