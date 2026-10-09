import Foundation

public extension Bundle {
    /// The bundle that holds every string catalog (I18N-01, I18N-06).
    /// Pass it as `bundle:` on every lookup: `Text("noteslist_title", tableName: "noteslist", bundle: .localization)`.
    static let localization = Bundle.module
}
