import CoreCommon
import CoreRepository
import SwiftUI

/// The module's only public API (CORE-05). The app owns the NavigationStack and decides what a tap does (ARCH-08).
public struct RatesListEntry: View {
    private let repository: any RatesRepository
    private let currencyFormatter: any CurrencyTextFormatting
    private let dateFormatter: any DateTextFormatting
    private let onRateClick: (String) -> Void

    public init(
        repository: any RatesRepository,
        currencyFormatter: any CurrencyTextFormatting,
        dateFormatter: any DateTextFormatting,
        onRateClick: @escaping (String) -> Void
    ) {
        self.repository = repository
        self.currencyFormatter = currencyFormatter
        self.dateFormatter = dateFormatter
        self.onRateClick = onRateClick
    }

    public var body: some View {
        RatesListRoute(
            viewModel: RatesListViewModel(
                repository: repository,
                mapper: RateItemUiMapper(currencyFormatter: currencyFormatter, dateFormatter: dateFormatter)
            ),
            onRateClick: onRateClick
        )
    }
}
