import CoreCommon

/// Everything the screen can show (ARCH-03). A missing currency is its own case, never an error (ERR-09).
enum RateDetailUiState: Equatable {
    case loading
    case notFound
    case error(AppError)
    case content(RateDetailContent)
}

struct RateDetailContent: Equatable {
    let code: String
    let name: String
    /// One unit of the currency in lira, formatted.
    let rateText: String
    /// One lira in the currency, formatted.
    let inverseText: String
    /// The converted amount; nil while the input is empty or invalid.
    let resultText: String?
    let isAmountInvalid: Bool
}
