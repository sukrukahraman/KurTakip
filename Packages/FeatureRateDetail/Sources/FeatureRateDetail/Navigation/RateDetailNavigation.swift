import CoreCommon
import CoreRepository
import SwiftUI

/// Navigation value for this screen. `Codable` so the back stack can be restored (ARCH-10).
public struct RateDetailKey: Hashable, Codable, Sendable {
    public let code: String

    public init(code: String) {
        self.code = code
    }
}

/// The module's only public API next to its key (CORE-05).
public struct RateDetailEntry: View {
    private let key: RateDetailKey
    private let repository: any RatesRepository
    private let currencyFormatter: any CurrencyTextFormatting

    public init(key: RateDetailKey, repository: any RatesRepository, currencyFormatter: any CurrencyTextFormatting) {
        self.key = key
        self.repository = repository
        self.currencyFormatter = currencyFormatter
    }

    public var body: some View {
        RateDetailRoute(
            viewModel: RateDetailViewModel(code: key.code, repository: repository, formatter: currencyFormatter)
        )
    }
}
