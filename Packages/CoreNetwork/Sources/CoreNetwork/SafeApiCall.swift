import CoreCommon
import Foundation

private let backoffFactor = 2
private let firstServerErrorCode = 500

/// Runs an API call and maps every failure to ``AppError`` (ERR-01). Transient failures (no network, 5xx) are retried
/// with exponential backoff (DATA-03); client errors and parse errors fail immediately. Wrap every call in this
/// function instead of writing retry loops.
///
/// Only cancellation escapes as an error, so structured concurrency keeps working (ERR-05).
public func safeApiCall<Response: Sendable>(
    retry: RetryPolicy = .standard,
    _ block: @Sendable () async throws -> Response
) async throws(CancellationError) -> AppResult<Response> {
    var backoff = retry.initialBackoff
    var attemptNumber = 1
    while true {
        let result = try await attempt(block)
        guard case .failure(let error) = result, error.isTransient, attemptNumber < retry.maxAttempts else {
            return result
        }
        do {
            try await retry.sleep(backoff)
        } catch {
            throw CancellationError()
        }
        backoff = min(backoff * backoffFactor, retry.maxBackoff)
        attemptNumber += 1
    }
}

private func attempt<Response: Sendable>(
    _ block: @Sendable () async throws -> Response
) async throws(CancellationError) -> AppResult<Response> {
    do {
        return .success(try await block())
    } catch is CancellationError {
        throw CancellationError()
    } catch let error as URLError {
        // A cancelled URLSession task is task cancellation; a cancellation nobody asked for is a rejected
        // certificate pin (the delegate cancels the challenge), which retrying cannot fix (ERR-08).
        if error.code == .cancelled, Task.isCancelled { throw CancellationError() }
        return .failure(error.appError)
    } catch let error as HTTPError {
        return .failure(error.appError)
    } catch {
        // Decoding and everything unexpected: not retried.
        return .failure(.unknown)
    }
}

private extension URLError {
    var appError: AppError {
        switch code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost,
             .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff:
            .network
        default:
            // TLS failures and rejected pins are not connectivity problems and are never retried (ERR-08).
            .unknown
        }
    }
}

private extension HTTPError {
    var appError: AppError {
        switch self {
        case .status(let code): .server(code: code)
        case .invalidResponse: .unknown
        }
    }
}

private extension AppError {
    var isTransient: Bool {
        switch self {
        case .network: true
        case .server(let code): code >= firstServerErrorCode
        case .unknown: false
        }
    }
}
