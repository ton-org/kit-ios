import SwiftUI

// Single seed-phrase slot: a leading index label sitting OUTSIDE the bordered
// TextField (border is only around the input). Border turns brand-blue when
// focused. Multi-word paste is detected by the presence of whitespace in a
// single edit and forwarded to `onPaste`; the field keeps only the first token
// so the parent can fan the rest out.
struct TONSeedPhraseField: View {
    let index: Int
    @Binding var word: String
    var isFocused: FocusState<Int?>.Binding
    var onPaste: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index + 1)")
                .textStyle(.body)
                .foregroundStyle(Color.tonTextTertiary)
                .frame(minWidth: 18, alignment: .trailing)

            TextField("", text: Binding(
                get: { word },
                set: { newValue in
                    let normalized = newValue
                        .lowercased()
                        .trimmingCharacters(in: .newlines)

                    if normalized.contains(where: \.isWhitespace) {
                        let firstToken = normalized
                            .split(whereSeparator: \.isWhitespace)
                            .first
                            .map(String.init) ?? ""
                        word = firstToken
                        onPaste(normalized)
                    } else {
                        word = normalized.trimmingCharacters(in: .whitespaces)
                    }
                }
            ))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textStyle(.body)
            .foregroundStyle(Color.tonTextPrimary)
            .focused(isFocused, equals: index)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isFocused.wrappedValue == index ? Color.tonTextBrand : Color.tonBgFillTertiary,
                        lineWidth: isFocused.wrappedValue == index ? 2 : 1
                    )
            )
            .contentShape(.rect)
            .onTapGesture { isFocused.wrappedValue = index }
        }
    }
}
