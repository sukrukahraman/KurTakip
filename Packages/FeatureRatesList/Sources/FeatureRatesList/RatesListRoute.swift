import SwiftUI

/// Owns the ViewModel and wires it to the stateless screen (COMP-01). No layout lives here.
struct RatesListRoute: View {
    @State private var viewModel: RatesListViewModel
    private let onRateClick: (String) -> Void

    init(viewModel: RatesListViewModel, onRateClick: @escaping (String) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onRateClick = onRateClick
    }

    var body: some View {
        RatesListScreen(
            uiState: viewModel.uiState,
            query: Bindable(viewModel).query,
            onRateClick: onRateClick,
            onRetry: viewModel.onRetry,
            onRefresh: { await viewModel.refresh() },
            onRefreshErrorShown: viewModel.onRefreshErrorShown
        )
        .task(id: viewModel.observeAttempt) { await viewModel.start() }
    }
}
