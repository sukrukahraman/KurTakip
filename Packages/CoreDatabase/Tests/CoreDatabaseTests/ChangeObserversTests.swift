import Foundation
import Testing
@testable import CoreDatabase

@Suite
struct ChangeObserversTests {
    @Test
    func publish_reachesEveryObserver() async throws {
        var observers = ChangeObservers<Int>()
        let first = AsyncThrowingStream.makeStream(of: Int.self, throwing: Error.self)
        let second = AsyncThrowingStream.makeStream(of: Int.self, throwing: Error.self)
        observers.add(first.continuation, id: UUID())
        observers.add(second.continuation, id: UUID())

        observers.publish(7)
        first.continuation.finish()
        second.continuation.finish()

        #expect(try await first.stream.reduce(into: []) { $0.append($1) } == [7])
        #expect(try await second.stream.reduce(into: []) { $0.append($1) } == [7])
    }

    @Test
    func remove_stopsDelivery() {
        var observers = ChangeObservers<Int>()
        let id = UUID()
        observers.add(AsyncThrowingStream.makeStream(of: Int.self, throwing: Error.self).continuation, id: id)

        observers.remove(id: id)

        #expect(observers.isEmpty)
    }
}
