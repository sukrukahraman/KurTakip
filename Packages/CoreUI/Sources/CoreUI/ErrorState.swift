import CoreDesignSystem
import CoreLocalization
import SwiftUI

public struct ErrorState: View {
    private let message: String
    private let onRetry: () -> Void

    public init(message: String, onRetry: @escaping () -> Void) {
        self.message = message
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: KurTakipTheme.spacing.medium) {
            Text(message)
                .font(KurTakipTheme.typography.body)
                .multilineTextAlignment(.center)
            KurTakipButton(
                String(localized: "common_retry", table: "common", bundle: .localization),
                action: onRetry
            )
        }
        .padding(KurTakipTheme.spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Light") {
    ErrorState(message: "No internet connection.") {}.appTheme()
}

#Preview("Dark") {
    ErrorState(message: "No internet connection.") {}.appTheme().preferredColorScheme(.dark)
}
