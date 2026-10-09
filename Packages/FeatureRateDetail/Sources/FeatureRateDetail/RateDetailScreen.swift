import CoreDesignSystem
import CoreLocalization
import CoreUI
import SwiftUI

/// Stateless: state in, events out. Previewable and testable with any state (COMP-01).
struct RateDetailScreen: View {
    let uiState: RateDetailUiState
    @Binding var amountText: String
    let onRetry: () -> Void

    var body: some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }

    private var title: String {
        if case .content(let content) = uiState { return content.code }
        return String(localized: "ratedetail_title", table: "ratedetail", bundle: .localization)
    }

    @ViewBuilder
    private var content: some View {
        switch uiState {
        case .loading:
            LoadingState()
        case .error(let error):
            ErrorState(message: error.message, onRetry: onRetry)
        case .notFound:
            EmptyState(
                message: String(localized: "ratedetail_not_found", table: "ratedetail", bundle: .localization),
                systemImage: "questionmark.circle"
            )
        case .content(let content):
            RateDetailBody(content: content, amountText: $amountText)
        }
    }
}

private struct RateDetailBody: View {
    let content: RateDetailContent
    @Binding var amountText: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KurTakipTheme.spacing.large) {
                VStack(alignment: .leading, spacing: KurTakipTheme.spacing.small) {
                    Text(content.name)
                        .font(KurTakipTheme.typography.title)
                    Text(String(
                        localized: "ratedetail_one_unit \(content.code) \(content.rateText)",
                        table: "ratedetail",
                        bundle: .localization
                    ))
                    .font(KurTakipTheme.typography.headline)
                    Text(String(
                        localized: "ratedetail_inverse \(content.inverseText)",
                        table: "ratedetail",
                        bundle: .localization
                    ))
                    .font(KurTakipTheme.typography.body)
                    .foregroundStyle(KurTakipTheme.colors.onSurfaceVariant)
                }
                KurTakipTextField(
                    String(localized: "ratedetail_amount_label", table: "ratedetail", bundle: .localization),
                    text: $amountText,
                    errorText: content.isAmountInvalid
                        ? String(localized: "ratedetail_amount_invalid", table: "ratedetail", bundle: .localization)
                        : nil,
                    keyboardType: .decimalPad
                )
                if let resultText = content.resultText {
                    Text(String(
                        localized: "ratedetail_result \(resultText)",
                        table: "ratedetail",
                        bundle: .localization
                    ))
                    .font(KurTakipTheme.typography.title)
                    .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(KurTakipTheme.spacing.medium)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview("Content") {
    NavigationStack {
        RateDetailScreen(uiState: .content(RateDetailPreviewData.content), amountText: .constant("1000"), onRetry: {})
    }
    .appTheme()
}

#Preview("Content, dark") {
    NavigationStack {
        RateDetailScreen(uiState: .content(RateDetailPreviewData.content), amountText: .constant("1000"), onRetry: {})
    }
    .appTheme()
    .preferredColorScheme(.dark)
}

#Preview("Not found") {
    NavigationStack {
        RateDetailScreen(uiState: .notFound, amountText: .constant(""), onRetry: {})
    }
    .appTheme()
}

#Preview("Error") {
    NavigationStack {
        RateDetailScreen(uiState: .error(.unknown), amountText: .constant(""), onRetry: {})
    }
    .appTheme()
}
