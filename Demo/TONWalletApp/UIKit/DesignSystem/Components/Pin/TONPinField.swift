import SwiftUI

// PIN entry: visible dot row + invisible TextField that opens the system numeric keypad.
// Tapping the dots refocuses the field. Non-digit input is filtered. `onComplete` fires
// once `pin.count == length`.
struct TONPinField: View {
    @Binding var pin: String
    let length: Int
    let isError: Bool
    let onComplete: (String) -> Void
    @FocusState private var focused: Bool

    init(
        pin: Binding<String>,
        length: Int = 4,
        isError: Bool,
        onComplete: @escaping (String) -> Void
    ) {
        self._pin = pin
        self.length = length
        self.isError = isError
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .opacity(0)
                .frame(width: 1, height: 1)
                .onChange(of: pin) { newValue in
                    let digits = String(newValue.filter(\.isNumber).prefix(length))
                    if digits != newValue { pin = digits }
                    if digits.count == length { onComplete(digits) }
                }

            TONPinDots(filled: pin.count, length: length, isError: isError)
                .contentShape(.rect)
                .onTapGesture { focused = true }
        }
        .onAppear { focused = true }
    }
}

#Preview {
    StatefulPreview()
}

private struct StatefulPreview: View {
    @State private var pin = ""
    @State private var isError = false
    var body: some View {
        TONPinField(pin: $pin, isError: isError) { entered in
            isError = (entered != "1234")
        }
        .padding()
    }
}
