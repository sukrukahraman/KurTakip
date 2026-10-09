import Foundation
import SwiftData
import Testing
@testable import CoreDatabase

@Suite
struct AppDatabaseTests {
    @Test
    func inMemoryDatabase_opensWithTheCurrentSchema() throws {
        let database = try AppDatabase(inMemory: true)

        #expect(database.container.schema.entities.count == CurrentSchema.models.count)
    }

    @Test
    func openCache_withACorruptStoreFile_fallsBackToAnInMemoryDatabase() throws {
        let url = URL.temporaryDirectory.appending(path: "corrupt-\(UUID().uuidString).store")
        try Data("this is not a database".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(throws: (any Error).self) { try AppDatabase(storeURL: url) } // the premise: opening it really fails

        let database = try AppDatabase.openCache(storeURL: url)

        #expect(database.container.schema.entities.count == CurrentSchema.models.count)
    }

    @Test
    func migrationPlan_listsEveryVersionOnceInAscendingOrder() {
        let versions = AppMigrationPlan.schemas.map { $0.versionIdentifier }

        #expect(versions == versions.sorted())
        #expect(Set(versions).count == versions.count)
    }

    @Test
    func migrationPlan_hasOneStageBetweenEachPairOfVersions() {
        #expect(AppMigrationPlan.stages.count == AppMigrationPlan.schemas.count - 1)
    }

    @Test
    func currentSchema_isTheNewestVersionInThePlan() {
        #expect(CurrentSchema.versionIdentifier == AppMigrationPlan.schemas.last?.versionIdentifier)
    }
}
