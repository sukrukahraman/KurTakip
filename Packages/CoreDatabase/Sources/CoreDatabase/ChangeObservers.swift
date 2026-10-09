import Foundation

/// Fan-out of store changes to `AsyncThrowingStream` observers (DATA-06). Each store actor owns one instance and
/// calls `publish` after every successful write, so the database stays the single source of truth.
struct ChangeObservers<Value: Sendable> {
    typealias Continuation = AsyncThrowingStream<Value, Error>.Continuation

    private var continuations: [UUID: Continuation] = [:]

    var isEmpty: Bool { continuations.isEmpty }

    mutating func add(_ continuation: Continuation, id: UUID) {
        continuations[id] = continuation
    }

    mutating func remove(id: UUID) {
        continuations[id] = nil
    }

    func publish(_ value: Value) {
        for continuation in continuations.values { continuation.yield(value) }
    }
}
