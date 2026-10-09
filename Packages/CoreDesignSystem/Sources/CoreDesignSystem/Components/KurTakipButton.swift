import SwiftUI

/// Primary button. The title is a parameter: the designsystem never looks up string catalogs (DS-03).
public struct KurTakipButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(KurTakipTheme.typography.headline)
                .foregroundStyle(KurTakipTheme.colors.onPrimary)
                .frame(maxWidth: .infinity, minHeight: KurTakipTheme.spacing.minTouchTarget)
        }
        .buttonStyle(.borderedProminent)
        .tint(KurTakipTheme.colors.primary)
    }
}

#Preview("Light") {
    KurTakipButton("Retry") {}
        .padding()
        .appTheme()
}

#Preview("Dark") {
    KurTakipButton("Retry") {}
        .padding()
        .appTheme()
        .preferredColorScheme(.dark)
}
