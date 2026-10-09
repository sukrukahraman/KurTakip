import CoreCommon
import CoreModel

/// Domain to UI mapping lives here, never inside a view body (ARCH-06).
struct RateItemUiMapper {
    let currencyFormatter: any CurrencyTextFormatting
    let dateFormatter: any DateTextFormatting

    func map(_ rate: ExchangeRate) -> RateItemUi {
        RateItemUi(
            id: rate.code,
            code: rate.code,
            name: currencyFormatter.name(forCode: rate.code),
            rateText: currencyFormatter.rateText(rate.tryPerUnit)
        )
    }

    /// The newest quote day among `rates`, formatted; empty when there are none.
    func updatedOnText(for rates: [ExchangeRate]) -> String {
        guard let newest = rates.map(\.quotedOn).max() else { return "" }
        return dateFormatter.text(for: newest)
    }
}
