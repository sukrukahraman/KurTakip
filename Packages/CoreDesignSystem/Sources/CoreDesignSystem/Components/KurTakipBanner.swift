import SwiftUI

/// A transient message pinned over the content, for failures that leave the screen usable. The message arrives
/// already localized (DS-03).
public struct KurTakipBanner: View {
    private let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        Text(message)
            .font(KurTakipTheme.typography.callout)
            .foregroundStyle(KurTakipTheme.colors.onError)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: KurTakipTheme.spacing.minTouchTarget, alignment: .leading)
            .padding(.horizontal, KurTakipTheme.spacing.medium)
            .background(KurTakipTheme.colors.error, in: .rect(cornerRadius: KurTakipTheme.spacing.cornerRadius))
            .padding(KurTakipTheme.spacing.medium)
            .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    KurTakipBanner(message: "Couldn't refresh. Showing the last saved data.").appTheme()
}

#Preview("Dark") {
    KurTakipBanner(message: "Couldn't refresh. Showing the last saved data.").appTheme().preferredColorScheme(.dark)
}
