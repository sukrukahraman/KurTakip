import CoreDesignSystem
import FeatureRateDetail
import FeatureRatesList
import SwiftUI

/// The only place that knows several features and owns the navigation stack (ARCH-01, ARCH-08). Features expose a
/// key and an entry view and report taps through callbacks; this file connects them. Navigate with
/// `router.navigate(to:)` and go back with `router.goBack()` (ARCH-10).
struct AppRoot: View {
    @State private var router = Router()
    @State private var container = AppContainer()

    var body: some View {
        NavigationStack(path: $router.path) {
            RatesListEntry(
                repository: container.repositories.rates,
                currencyFormatter: container.currencyFormatter,
                dateFormatter: container.dateFormatter,
                onRateClick: { router.navigate(to: RateDetailKey(code: $0)) }
            )
            .navigationDestination(for: RateDetailKey.self) { key in
                RateDetailEntry(
                    key: key,
                    repository: container.repositories.rates,
                    currencyFormatter: container.currencyFormatter
                )
            }
        }
        .appTheme()
    }
}
