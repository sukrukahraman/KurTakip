import SwiftUI

/// Access to the app's design tokens: `KurTakipTheme.colors.primary`, `KurTakipTheme.spacing.medium`.
public enum KurTakipTheme {
    public static let colors = KurTakipColors()
    public static let spacing = KurTakipSpacing()
    public static let typography = KurTakipTypography()
}

public extension View {
    /// Applies the app tint and default text color. Put it once at the root and on every preview.
    func appTheme() -> some View {
        tint(KurTakipTheme.colors.primary)
            .foregroundStyle(KurTakipTheme.colors.onSurface)
    }
}
