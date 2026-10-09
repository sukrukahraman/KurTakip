import CoreDesignSystem
import SwiftUI

struct RateListItem: View {
    let rate: RateItemUi

    var body: some View {
        // At accessibility text sizes the rate drops below the name instead of squeezing both.
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                names
                Spacer(minLength: KurTakipTheme.spacing.medium)
                rateText
            }
            VStack(alignment: .leading, spacing: KurTakipTheme.spacing.extraSmall) {
                names
                rateText
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, KurTakipTheme.spacing.small)
        .accessibilityElement(children: .combine)
    }

    private var names: some View {
        VStack(alignment: .leading, spacing: KurTakipTheme.spacing.extraSmall) {
            Text(rate.code)
                .font(KurTakipTheme.typography.headline)
            Text(rate.name)
                .font(KurTakipTheme.typography.caption)
                .foregroundStyle(KurTakipTheme.colors.onSurfaceVariant)
        }
    }

    private var rateText: some View {
        Text(rate.rateText)
            .font(KurTakipTheme.typography.body)
            .monospacedDigit()
    }
}

#Preview("Light") {
    RateListItem(rate: RatesListPreviewData.rates[0])
        .padding()
        .appTheme()
}

#Preview("Dark") {
    RateListItem(rate: RatesListPreviewData.rates[0])
        .padding()
        .appTheme()
        .preferredColorScheme(.dark)
}
