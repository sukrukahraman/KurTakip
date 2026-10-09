import CoreDesignSystem
import CoreLocalization
import CoreUI
import SwiftUI

/// Stateless: state in, events out. Previewable and testable with any state (COMP-01).
struct RatesListScreen: View {
    private static let bannerDuration: Duration = .seconds(3)

    let uiState: RatesListUiState
    @Binding var query: String
    let onRateClick: (String) -> Void
    let onRetry: () -> Void
    let onRefresh: () async -> Void
    let onRefreshErrorShown: () -> Void

    var body: some View {
        content
            .navigationTitle(String(localized: "ratelist_title", table: "ratelist", bundle: .localization))
            .searchable(
                text: $query,
                prompt: String(localized: "ratelist_search_prompt", table: "ratelist", bundle: .localization)
            )
            .safeAreaInset(edge: .bottom) { refreshErrorBanner }
    }

    @ViewBuilder
    private var content: some View {
        switch uiState {
        case .loading:
            LoadingState()
        case .error(let error):
            ErrorState(message: error.message, onRetry: onRetry)
        case .empty:
            // ERR-07: the empty state stays inside the refreshable list, so pull-to-refresh still works.
            RatesList(content: nil, onRateClick: onRateClick, onRefresh: onRefresh)
        case .content(let content):
            RatesList(content: content, onRateClick: onRateClick, onRefresh: onRefresh)
        }
    }

    @ViewBuilder
    private var refreshErrorBanner: some View {
        if case .content(let content) = uiState, let error = content.refreshError {
            KurTakipBanner(
                message: String(localized: "ratelist_refresh_failed", table: "ratelist", bundle: .localization)
            )
            .task(id: error) {
                // COMP-08: also when the screen leaves mid-delay, so the event is not replayed on return.
                try? await Task.sleep(for: Self.bannerDuration)
                onRefreshErrorShown()
            }
        }
    }
}

private struct RatesList: View {
    let content: RatesListContent?
    let onRateClick: (String) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        List {
            if let content {
                Section {
                    if content.rates.isEmpty, content.isSearching {
                        EmptyState(
                            message: String(
                                localized: "ratelist_search_empty",
                                table: "ratelist",
                                bundle: .localization
                            ),
                            systemImage: "magnifyingglass"
                        )
                        .containerRelativeFrame(.vertical)
                        .listRowSeparator(.hidden)
                    }
                    ForEach(content.rates) { rate in
                        Button { onRateClick(rate.code) } label: { RateListItem(rate: rate) }
                    }
                } header: {
                    Text(String(
                        localized: "ratelist_count \(content.rates.count)",
                        table: "ratelist",
                        bundle: .localization
                    ))
                } footer: {
                    Text(String(
                        localized: "ratelist_updated \(content.updatedOnText)",
                        table: "ratelist",
                        bundle: .localization
                    ))
                }
            } else {
                EmptyState(message: String(localized: "ratelist_empty", table: "ratelist", bundle: .localization))
                    .containerRelativeFrame(.vertical)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable { await onRefresh() }
    }
}

#Preview("Content") {
    NavigationStack {
        RatesListScreen(
            uiState: .content(RatesListPreviewData.content),
            query: .constant(""), onRateClick: { _ in }, onRetry: {}, onRefresh: {},
            onRefreshErrorShown: {}
        )
    }
    .appTheme()
}

#Preview("Content, dark") {
    NavigationStack {
        RatesListScreen(
            uiState: .content(RatesListPreviewData.content),
            query: .constant(""), onRateClick: { _ in }, onRetry: {}, onRefresh: {},
            onRefreshErrorShown: {}
        )
    }
    .appTheme()
    .preferredColorScheme(.dark)
}

#Preview("Empty") {
    NavigationStack {
        RatesListScreen(
            uiState: .empty,
            query: .constant(""), onRateClick: { _ in }, onRetry: {}, onRefresh: {},
            onRefreshErrorShown: {}
        )
    }
    .appTheme()
}

#Preview("Error") {
    NavigationStack {
        RatesListScreen(
            uiState: .error(.network),
            query: .constant(""), onRateClick: { _ in }, onRetry: {}, onRefresh: {},
            onRefreshErrorShown: {}
        )
    }
    .appTheme()
}
