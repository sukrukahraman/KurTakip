import Foundation
import SwiftData

/// The schema the app runs on. When you add a version, point this at it (and nothing else changes).
typealias CurrentSchema = AppSchemaV1

/// Version 1 of the schema. Nest every `@Model` entity in this enum and list it in `models`.
///
/// A schema version that has shipped is never edited (DATA-04): copy it to `AppSchemaV2`, add a `MigrationStage` to
/// `AppMigrationPlan`, move `CurrentSchema` and write a migration test that opens a store file written by the old
/// version (TEST-08, see references/reference-feature.md).
public enum AppSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] { [RateEntity.self] }

    @Model
    final class RateEntity {
        @Attribute(.unique) var currencyCode: String
        var tryPerUnit: Double
        var quotedOn: Date

        init(currencyCode: String, tryPerUnit: Double, quotedOn: Date) {
            self.currencyCode = currencyCode
            self.tryPerUnit = tryPerUnit
            self.quotedOn = quotedOn
        }
    }
}

public enum AppMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [AppSchemaV1.self] }

    public static var stages: [MigrationStage] { [] }
}
