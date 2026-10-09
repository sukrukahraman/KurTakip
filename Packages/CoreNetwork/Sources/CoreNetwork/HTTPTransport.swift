import Foundation

/// The seam between `APIClient` and the network. Production uses `live(config:)`; tests pass a closure.
public struct HTTPTransport: Sendable {
    public var send: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    public init(send: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)) {
        self.send = send
    }

    private static let timeoutSeconds: TimeInterval = 20

    /// A pinned `URLSession` with explicit timeouts (DATA-02).
    public static func live(config: ApiConfig) -> HTTPTransport {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutSeconds
        configuration.timeoutIntervalForResource = timeoutSeconds * 2
        let session = URLSession(
            configuration: configuration,
            delegate: PinningSessionDelegate(pinner: CertificatePinner(pins: config.certPins)),
            delegateQueue: nil
        )
        return HTTPTransport { request in try await session.data(for: request) }
    }
}
