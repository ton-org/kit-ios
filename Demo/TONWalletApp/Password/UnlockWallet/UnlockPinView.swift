import SwiftUI

struct UnlockPinView: View {
    @StateObject private var viewModel = UnlockPinViewModel()
    @EnvironmentObject private var appStateManager: TONWalletAppStateManager
    @State private var showResetSheet = false

    var body: some View {
        TONPinScreen(
            title: "Enter your PIN",
            description: nil,
            pin: $viewModel.pin,
            error: $viewModel.error
        ) { entered in
            if viewModel.checkPin(entered) {
                appStateManager.unlock()
            }
        } trailing: {
            Button {
                showResetSheet = true
            } label: {
                Text("Forgot your PIN code?")
                    .textStyle(.callout)
                    .foregroundStyle(Color.tonTextTertiary)
            }
            .buttonStyle(.plain)
        }
        .task {
            if await viewModel.tryBiometryAuthentication() {
                appStateManager.unlock()
            }
        }
        .sheet(isPresented: $showResetSheet) {
            ForgotPinSheet(
                onReset: {
                    viewModel.reset()
                    showResetSheet = false
                    appStateManager.reset()
                },
                onClose: { showResetSheet = false }
            )
            .automaticHeightPresentationDetents()
            .presentationDragIndicator(.hidden)
        }
    }
}

// Bottom sheet from figma `40001176:28842`:
//   • white bg, rounded-top-16
//   • px-16 py-24
//   • Title (Inter Bold 20, black, left-aligned)
//   • Description (SF Pro Regular 17, gray, left-aligned)
//   • Bezeled "Reset wallet" button (light blue bg, brand text)
//   • Top-right X close button (44×44 with 28×28 icon)
private struct ForgotPinSheet: View {
    let onReset: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Forgot your PIN code?")
                    .textStyle(.title3Bold)
                    .foregroundStyle(Color.tonTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("There is no password recovery option. If you created a wallet backup, you can restore the wallet using your backup passphrase and then set a new PIN code.")
                    .textStyle(.body)
                    .foregroundStyle(Color.tonTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Reset wallet", action: onReset)
                .buttonStyle(.ton(.secondary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .fixedSize(horizontal: false, vertical: true)
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Color.tonTextTertiary, Color.tonBgLightGray)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .padding(.top, 8)
            .padding(.trailing, 8)
        }
    }
}
