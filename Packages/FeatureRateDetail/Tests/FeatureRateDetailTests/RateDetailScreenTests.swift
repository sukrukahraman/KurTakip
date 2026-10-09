import CoreCommon
import CoreTesting
import CoreUI
import SwiftUI
import Testing
import ViewInspector
@testable import FeatureRateDetail

@MainActor
@Suite
struct RateDetailScreenTests {
    private func screen(
        _ state: RateDetailUiState,
        amountText: Binding<String> = .constant(""),
        onRetry: @escaping () -> Void = {}
    ) -> RateDetailScreen {
        RateDetailScreen(uiState: state, amountText: amountText, onRetry: onRetry)
    }

    private func content(resultText: String?, isAmountInvalid: Bool) -> RateDetailContent {
        RateDetailContent(
            code: "USD",
            name: "US Dollar",
            rateText: "₺49",
            inverseText: "$0,02",
            resultText: resultText,
            isAmountInvalid: isAmountInvalid
        )
    }

    @Test
    func contentState_showsNameAndBothDirectionsOfTheRate() throws {
        let content = RateDetailPreviewData.content
        let sut = screen(.content(content))

        let oneUnit = localizedString("ratedetail_one_unit \(content.code) \(content.rateText)", table: "ratedetail")
        let inverse = localizedString("ratedetail_inverse \(content.inverseText)", table: "ratedetail")
        #expect(try sut.inspect().find(text: content.name).string() == content.name)
        #expect(try sut.inspect().find(text: oneUnit).string() == oneUnit)
        #expect(try sut.inspect().find(text: inverse).string() == inverse)
    }

    @Test
    func contentState_withResult_showsTheConvertedAmount() throws {
        let content = RateDetailPreviewData.content
        let sut = screen(.content(content))

        let result = localizedString("ratedetail_result \(content.resultText ?? "")", table: "ratedetail")

        #expect(try sut.inspect().find(text: result).string() == result)
    }

    @Test
    func contentState_withoutResult_hidesTheResultLine() throws {
        let content = content(resultText: nil, isAmountInvalid: false)
        let sut = screen(.content(content))

        let result = localizedString("ratedetail_result \("")", table: "ratedetail")

        #expect(throws: (any Error).self) { try sut.inspect().find(text: result) }
    }

    @Test
    func contentState_invalidAmount_showsTheErrorLine() throws {
        let content = content(resultText: nil, isAmountInvalid: true)
        let sut = screen(.content(content))

        let message = localizedString("ratedetail_amount_invalid", table: "ratedetail")

        #expect(try sut.inspect().find(text: message).string() == message)
    }

    @Test
    func contentState_typingInTheField_updatesTheBinding() throws {
        var typed = ""
        let sut = screen(
            .content(RateDetailPreviewData.content),
            amountText: Binding(get: { typed }, set: { typed = $0 })
        )

        try sut.inspect().find(ViewType.TextField.self).setInput("250")

        #expect(typed == "250")
    }

    @Test
    func notFoundState_showsTheMessage() throws {
        let message = localizedString("ratedetail_not_found", table: "ratedetail")

        #expect(try screen(.notFound).inspect().find(text: message).string() == message)
    }

    @Test
    func errorState_retryTap_invokesCallback() throws {
        var retries = 0
        let sut = screen(.error(.network), onRetry: { retries += 1 })

        try sut.inspect().find(button: localizedString("common_retry", table: "common")).tap()

        #expect(retries == 1)
    }

    @Test
    func loadingState_showsProgress() throws {
        _ = try screen(.loading).inspect().find(ViewType.ProgressView.self)
    }
}
