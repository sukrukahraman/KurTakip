import CoreCommon
import Foundation

public enum HTTPError: Error, Equatable, Sendable {
    /// The server answered outside 200...299.
    case status(Int)
    /// The response was not an HTTP response.
    case invalidResponse
}

/// Thin typed JSON client. Repositories reach it through a small API protocol per resource (ARCH-04), never directly
/// from a feature. The API version is part of `ApiConfig.baseURL` (DATA-07).
public struct APIClient: Sendable {
    private static let successStatusCodes = 200...299
    private let baseURL: URL
    private let transport: HTTPTransport
    private let decoder: JSONDecoder
    private let logger = AppLogger.make(category: "network")

    public init(config: ApiConfig, transport: HTTPTransport? = nil, decoder: JSONDecoder = .api) {
        baseURL = config.baseURL
        self.transport = transport ?? .live(config: config)
        self.decoder = decoder
    }

    public func get<Response: Decodable & Sendable>(
        _ path: String,
        query: [URLQueryItem] = []
    ) async throws -> Response {
        let data = try await perform(method: "GET", path: path, query: query)
        return try decoder.decode(Response.self, from: data)
    }

    /// Sends a request that returns no body worth decoding (DELETE, 204 responses).
    public func send(method: String, _ path: String) async throws {
        _ = try await perform(method: method, path: path, query: [])
    }

    private func perform(method: String, path: String, query: [URLQueryItem]) async throws -> Data {
        var components = URLComponents(
            url: baseURL.appending(path: path.trimmingPrefix("/").description),
            resolvingAgainstBaseURL: false
        )
        if !query.isEmpty { components?.queryItems = query }
        guard let url = components?.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await transport.send(request)
        guard let http = response as? HTTPURLResponse else { throw HTTPError.invalidResponse }
        #if DEBUG
        // DATA-02: debug-only, path and status only. Never log headers, query strings or bodies (SEC-06).
        logger.debug("\(method) \(url.path()) -> \(http.statusCode)")
        #endif
        guard Self.successStatusCodes.contains(http.statusCode) else { throw HTTPError.status(http.statusCode) }
        return data
    }
}

public extension JSONDecoder {
    /// snake_case keys and ISO-8601 dates, the usual REST defaults.
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
