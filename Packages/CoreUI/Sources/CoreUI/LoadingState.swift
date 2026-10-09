import CoreLocalization
import SwiftUI

public struct LoadingState: View {
    public init() {}

    public var body: some View {
        ProgressView()
            .accessibilityLabel(String(localized: "common_loading", table: "common", bundle: .localization))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Light") {
    LoadingState().appTheme()
}

#Preview("Dark") {
    LoadingState().appTheme().preferredColorScheme(.dark)
}
