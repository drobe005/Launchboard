/// SwiftData VersionedSchema declarations — add a new enum + migration plan here whenever the model shape changes.
import SwiftData

public enum LaunchboardSchemaV1: VersionedSchema {
    public static var versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [AppEntry.self, AppGroup.self, SmartGroupRule.self, Favorite.self, AppSettings.self]
    }
}

// When the schema changes, add LaunchboardSchemaV2 and a MigrationPlan below:
//
// public enum LaunchboardMigrationPlan: SchemaMigrationPlan {
//     public static var schemas: [any VersionedSchema.Type] { [LaunchboardSchemaV1.self] }
//     public static var stages: [MigrationStage] { [] }
// }
