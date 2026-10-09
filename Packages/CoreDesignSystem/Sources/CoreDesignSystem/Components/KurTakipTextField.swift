import SwiftUI

/// A labelled text field with an optional error line. Label and error arrive already localized (DS-03).
public struct KurTakipTextField: View {
    private let label: String
    private let errorText: String?
    private let keyboardType: UIKeyboardType
    @Binding private var text: String

    public init(
        _ label: String,
        text: Binding<String>,
        errorText: String? = nil,
        keyboardType: UIKeyboardType = .default
    ) {
        self.label = label
        self.errorText = errorText
        self.keyboardType = keyboardType
        _text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: KurTakipTheme.spacing.extraSmall) {
            TextField(label, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: KurTakipTheme.spacing.minTouchTarget)
            if let errorText {
                Text(errorText)
                    .font(KurTakipTheme.typography.caption)
                    .foregroundStyle(KurTakipTheme.colors.error)
            }
        }
    }
}

#Preview("Light") {
    @Previewable @State var text = ""
    KurTakipTextField("Amount", text: $text, errorText: "Required").padding().appTheme()
}

#Preview("Dark") {
    @Previewable @State var text = "1000"
    KurTakipTextField("Amount", text: $text, keyboardType: .decimalPad).padding().appTheme().preferredColorScheme(.dark)
}
