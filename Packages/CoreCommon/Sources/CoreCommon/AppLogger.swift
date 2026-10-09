// coverage:exclude thin wrapper over os.Logger: there is no logic to test

import Foundation
import OSLog

/// The only logging entry point (OBS-01). `print`, `NSLog` and `os_log` stay forbidden.
/// Interpolated values are private in unified logging by default; never mark tokens or personal data `.public`.
public enum AppLogger {
    public static func make(category: String) -> Logger {
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: category)
    }
}
