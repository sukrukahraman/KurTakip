/// Sample data shared by previews and tests; the only place literal UI text is allowed.
enum RatesListPreviewData {
    static let rates = [
        RateItemUi(id: "EUR", code: "EUR", name: "Euro", rateText: "₺55,0712"),
        RateItemUi(id: "GBP", code: "GBP", name: "British Pound", rateText: "₺63,9034"),
        RateItemUi(id: "USD", code: "USD", name: "US Dollar", rateText: "₺49,2145"),
    ]

    static let content = RatesListContent(
        rates: rates,
        updatedOnText: "8 Oct 2026",
        isSearching: false,
        refreshError: nil
    )
}
