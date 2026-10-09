import CoreCommon
import CoreModel
import CoreRepository
import os

/// Hand-written fake for ViewModel tests (TEST-06). By default the observation stream emits the current rates and
/// finishes, so a test can `await viewModel.observe()` and then assert; set `streamStaysOpen` to keep it live.
public final class FakeRatesRepository: RatesRepository {
    private struct State {
        var rates: [ExchangeRate] = []
        var observeFailure: (any Error)?
        var refreshResult: AppResult<Void> = .success(())
        var refreshCount = 0
        var continuations: [AsyncThrowingStream<[ExchangeRate], Error>.Continuation] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let streamStaysOpen: Bool

    public init(rates: [ExchangeRate] = [], streamStaysOpen: Bool = false) {
        self.streamStaysOpen = streamStaysOpen
        state.withLock { $0.rates = rates }
    }

    public var refreshCount: Int { state.withLock(\.refreshCount) }

    public func emit(_ rates: [ExchangeRate]) {
        let continuations = state.withLock { state in
            state.rates = rates
            return state.continuations
        }
        for continuation in continuations { continuation.yield(rates) }
    }

    public func failObservation(with error: (any Error)?) {
        state.withLock { $0.observeFailure = error }
    }

    public func setRefreshResult(_ result: AppResult<Void>) {
        state.withLock { $0.refreshResult = result }
    }

    public func observeRates() async -> AsyncThrowingStream<[ExchangeRate], Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: [ExchangeRate].self, throwing: Error.self)
        let snapshot = state.withLock { state in
            if streamStaysOpen { state.continuations.append(continuation) }
            return (state.rates, state.observeFailure)
        }
        if let failure = snapshot.1 {
            continuation.finish(throwing: failure)
        } else {
            continuation.yield(snapshot.0)
            if !streamStaysOpen { continuation.finish() }
        }
        return stream
    }

    public func refresh() async throws(CancellationError) -> AppResult<Void> {
        state.withLock { state in
            state.refreshCount += 1
            return state.refreshResult
        }
    }
}
