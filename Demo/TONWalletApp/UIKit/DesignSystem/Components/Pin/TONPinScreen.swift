import SwiftUI

// Shared layout for both PIN-creation and PIN-unlock screens.
// Matches figma `40001176:24957` / `40001176:28800` / `40001176:25021` / `40001176:25043`:
//   • white background
//   • centered title (Inter Bold 20) + optional description (Inter Regular 16, gray)
//   • 32pt gap → dots row
//   • below dots: error text (red) — shown whenever `error != nil`, sits between dots and bottom slot
//   • bottom slot above keyboard: trailing closure (e.g. forgot link or primary Save button)
//
// Error auto-clears the moment the user starts typing again (so the UX isn't "stuck red").
struct TONPinScreen<Trailing: View>: View {
    let title: String
    let description: String?
    @Binding var pin: String
    @Binding var error: String?
    let length: Int
    let onComplete: (String) -> Void
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: String,
        description: String? = nil,
        pin: Binding<String>,
        error: Binding<String?>,
        length: Int = 4,
        onComplete: @escaping (String) -> Void,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.description = description
        self._pin = pin
        self._error = error
        self.length = length
        self.onComplete = onComplete
        self.trailing = trailing
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(maxHeight: 160)

            // Title + description
            VStack(spacing: 4) {
                Text(title)
                    .textStyle(.title3Bold)
                    .foregroundStyle(Color.tonTextPrimary)
                    .multilineTextAlignment(.center)
                if let description, !description.isEmpty {
                    Text(description)
                        .textStyle(.callout)
                        .foregroundStyle(Color.tonTextTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)

            Spacer().frame(height: 32)

            // Dots
            TONPinField(pin: $pin, length: length, isError: error != nil, onComplete: onComplete)

            // Error (always below dots, separate from bottom slot)
            Text(error ?? " ")
                .textStyle(.callout)
                .foregroundStyle(Color.tonTextError)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .opacity(error == nil ? 0 : 1)

            Spacer()

            // Bottom slot above keyboard
            trailing()
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tonBgPrimary.ignoresSafeArea())
        .onChange(of: pin) { newPin in
            // Type-to-clear: as soon as user starts typing again, drop the red state.
            if !newPin.isEmpty, error != nil {
                error = nil
            }
        }
    }
}

#Preview { StatefulPreview() }

private struct StatefulPreview: View {
    @State private var pin = ""
    @State private var error: String?
    var body: some View {
        TONPinScreen(
            title: "Enter your PIN",
            description: nil,
            pin: $pin,
            error: $error
        ) { entered in
            error = entered == "1234" ? nil : "Incorrect PIN. Please try again."
            pin = ""
        } trailing: {
            Text("Forgot your PIN code?")
                .textStyle(.callout)
                .foregroundStyle(Color.tonTextTertiary)
        }
    }
}
