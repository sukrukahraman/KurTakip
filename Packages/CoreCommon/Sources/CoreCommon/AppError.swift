/// Typed failure shared by every layer (ERR-01). The UI turns it into text through CoreUI's `AppError.message`.
public enum AppError: Error, Equatable, Sendable {
    /// No connectivity, or the request timed out.
    case network
    /// The server answered with an HTTP error status.
    case server(code: Int)
    /// Anything unexpected (parsing, storage, programming errors surfaced as data).
    case unknown
}

/// Result of an operation that can fail with a typed ``AppError``.
public typealias AppResult<Success> = Result<Success, AppError>

public extension Result where Failure == AppError {
    /// The typed error of a failed result, nil on success. Works for `Void` results, which are not `Equatable`.
    var error: AppError? {
        if case .failure(let error) = self { error } else { nil }
    }
}
