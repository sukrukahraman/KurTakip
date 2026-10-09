import CoreCommon

/// Everything the screen can show (ARCH-03). Loading, content, empty and error are separate cases (ERR-06).
enum RatesListUiState: Equatable {
    case loading
    case empty
    case error(AppError)
    case content(RatesListContent)
}

struct RatesListContent: Equatable {
    /// The rates matching the search, in code order. Empty with `isSearching` means nothing matched.
    let rates: [RateItemUi]
    /// The quote day of the newest rate, already formatted.
    let updatedOnText: String
    let isSearching: Bool
    /// A refresh failed while saved rates are on screen: show a banner, keep the content (ERR-06).
    let refreshError: AppError?
}

struct RateItemUi: Equatable, Identifiable {
    let id: String
    let code: String
    let name: String
    let rateText: String
}
