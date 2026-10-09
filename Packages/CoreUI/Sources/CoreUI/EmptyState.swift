import SwiftUI

/// An actionable empty state is the caller's job (ERR-07): keep it inside the refreshable list or add an action.
public struct EmptyState: View {
    private let message: String
    private let systemImage: String

    public init(message: String, systemImage: String = "tray") {
        self.message = message
        self.systemImage = systemImage
    }

    public var body: some View {
        ContentUnavailableView {
            Label(message, systemImage: systemImage)
        }
    }
}

#Preview("Light") {
    EmptyState(message: "Nothing here yet").appTheme()
}

#Preview("Dark") {
    EmptyState(message: "Nothing here yet").appTheme().preferredColorScheme(.dark)
}
