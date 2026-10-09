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
