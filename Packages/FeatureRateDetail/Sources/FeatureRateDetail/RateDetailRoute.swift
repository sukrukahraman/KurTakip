import SwiftUI

/// Owns the ViewModel and wires it to the stateless screen (COMP-01). No layout lives here.
struct RateDetailRoute: View {
    @State private var viewModel: RateDetailViewModel

    init(viewModel: RateDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        RateDetailScreen(
            uiState: viewModel.uiState,
            amountText: Bindable(viewModel).amountText,
            onRetry: viewModel.onRetry
        )
        .task(id: viewModel.observeAttempt) { await viewModel.observe() }
    }
}
