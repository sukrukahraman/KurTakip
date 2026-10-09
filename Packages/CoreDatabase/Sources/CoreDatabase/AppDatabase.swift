import Foundation
import os
import SwiftData

/// Parallel tests each open their own in-memory container. An intermittent Core Data crash (EXC_BAD_ACCESS in
/// `_generateTriggerSQL`, seen while four stores were loading at the same instant) is not fully explained, so creation
/// is serialized as a cheap mitigation.
private let creationLock = OSAllocatedUnfairLock()

/// Builds the app's single `ModelContainer` from the versioned schema and its migration plan (DATA-04).
public struct AppDatabase: Sendable {
    public let container: ModelContainer

    /// `storeURL` lets a migration test open a store file written by an older schema version.
    public init(inMemory: Bool = false, storeURL: URL? = nil) throws {
        if !inMemory, storeURL == nil {
            // A fresh app container has no Application Support folder yet, and the default store lives there.
            try FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        }
        let schema = Schema(versionedSchema: CurrentSchema.self)
        let configuration = if let storeURL {
            ModelConfiguration(schema: schema, url: storeURL)
        } else {
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        }
        container = try creationLock.withLock {
            try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [configuration]
            )
        }
    }
}
