import SwiftUI
import UIKit

/// Brand tokens. Replace the hex values with the design source's palette (Figma variables or
/// `scripts/extract_palette.py`) in the designsystem task; nothing outside this module may define colors (RES-01).
public struct KurTakipColors: Sendable {
    public let primary = Color(light: 0x0B6E4F, dark: 0x7ED9B5)
    public let onPrimary = Color(light: 0xFFFFFF, dark: 0x003826)
    public let secondary = Color(light: 0x4A635A, dark: 0xB1CCC1)
    public let background = Color(light: 0xFBFDF9, dark: 0x101412)
    public let surface = Color(light: 0xFFFFFF, dark: 0x1A1D1B)
    public let onSurface = Color(light: 0x191C1A, dark: 0xE1E3DF)
    public let onSurfaceVariant = Color(light: 0x404944, dark: 0xC0C9C2)
    public let outline = Color(light: 0x707973, dark: 0x8A938D)
    public let error = Color(light: 0xBA1A1A, dark: 0xFFB4AB)
    public let onError = Color(light: 0xFFFFFF, dark: 0x690005)
}

extension Color {
    /// A color that follows the light/dark appearance without an asset catalog.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
