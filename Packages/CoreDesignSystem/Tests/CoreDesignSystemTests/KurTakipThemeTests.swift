import SwiftUI
import Testing
import UIKit
@testable import CoreDesignSystem

@Suite
struct KurTakipThemeTests {
    private func resolved(_ color: Color, _ style: UIUserInterfaceStyle) -> UIColor {
        UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    }

    @Test
    func everyBrandColorHasADistinctDarkModeValue() {
        let colors = KurTakipTheme.colors
        let all = [
            colors.primary, colors.onPrimary, colors.secondary, colors.background, colors.surface,
            colors.onSurface, colors.onSurfaceVariant, colors.outline, colors.error,
        ]

        for color in all {
            #expect(resolved(color, .light) != resolved(color, .dark))
        }
    }

    @Test
    func touchTargetsMeetTheMinimumSize() {
        #expect(KurTakipTheme.spacing.minTouchTarget >= 44)
    }

    @Test
    func spacingGrowsMonotonically() {
        let spacing = KurTakipTheme.spacing

        #expect(spacing.extraSmall < spacing.small)
        #expect(spacing.small < spacing.medium)
        #expect(spacing.medium < spacing.large)
        #expect(spacing.large < spacing.extraLarge)
    }
}
