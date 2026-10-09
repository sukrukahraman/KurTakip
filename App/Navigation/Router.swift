import Observation
import SwiftUI

/// Owns the NavigationStack path and is the only code that changes it (ARCH-08, ARCH-10). Features never see it.
@MainActor
@Observable
final class Router {
    var path = NavigationPath()

    /// What was pushed through this router, so the top of the stack can be inspected (`NavigationPath` cannot).
    private var keys: [AnyHashable] = []

    /// Pushes `key` unless it is already on top, so a double tap never stacks duplicates.
    func navigate(to key: some Hashable) {
        syncWithPath()
        guard keys.last != AnyHashable(key) else { return }
        keys.append(key)
        path.append(key)
    }

    /// Pops one screen. The root screen is not part of the path, so there is never anything to pop on it.
    func goBack() {
        syncWithPath()
        guard !keys.isEmpty else { return }
        keys.removeLast()
        path.removeLast()
    }

    /// Replaces the whole stack, for deep links and notification taps. Pass the start screen first so back works.
    func reset(to newKeys: [any Hashable]) {
        keys = []
        path = NavigationPath()
        for key in newKeys {
            keys.append(AnyHashable(key))
            path.append(key)
        }
    }

    /// The system back gesture shortens `path` without telling us; drop the keys that are gone.
    private func syncWithPath() {
        if keys.count > path.count { keys.removeLast(keys.count - path.count) }
    }
}
