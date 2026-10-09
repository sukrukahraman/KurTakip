import SwiftUI

/// A transient message pinned over the content, for failures that leave the screen usable. The message arrives
/// already localized (DS-03). It announces itself to VoiceOver when it appears, because it goes away on its own.
public struct KurTakipBanner: View {
    private let message: String
    private let announce: (String) -> Void

    /// `announce` is a seam for tests; the default posts a VoiceOver announcement.
    public init(
        message: String,
        announce: @escaping (String) -> Void = { AccessibilityNotification.Announcement($0).post() }
    ) {
        self.message = message
        self.announce = announce
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
            .onAppear { announce(message) }
    }
}

#Preview("Light") {
    KurTakipBanner(message: "Couldn't refresh. Showing the last saved data.").appTheme()
}

#Preview("Dark") {
    KurTakipBanner(message: "Couldn't refresh. Showing the last saved data.").appTheme().preferredColorScheme(.dark)
}
