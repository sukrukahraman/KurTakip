import CoreGraphics

/// Spacing and size tokens (RES-02). Features use `KurTakipTheme.spacing.medium` instead of literal numbers.
public struct KurTakipSpacing: Sendable {
    public let extraSmall: CGFloat = 4
    public let small: CGFloat = 8
    public let medium: CGFloat = 16
    public let large: CGFloat = 24
    public let extraLarge: CGFloat = 32
    public let cornerRadius: CGFloat = 12
    /// Apple's minimum comfortable hit target (A11Y-02).
    public let minTouchTarget: CGFloat = 44
}
