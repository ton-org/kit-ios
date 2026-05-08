import SwiftUI

struct CreatePinView: View {
    @StateObject private var viewModel = CreatePinViewModel()
    @EnvironmentObject private var appStateManager: TONWalletAppStateManager

    var body: some View {
        TONPinScreen(
            title: viewModel.screenTitle,
            description: viewModel.screenDescription,
            pin: $viewModel.pin,
            error: $viewModel.error
        ) { entered in
            // Auto-advance only happens in the entering phase. Confirm phase requires Save tap.
            if viewModel.isEntering {
                viewModel.advanceToConfirming(with: entered)
            }
        } trailing: {
            if !viewModel.isEntering {
                Button("Save") {
                    Task {
                        let saved = await viewModel.commitConfirmation()
                        if saved { appStateManager.unlock() }
                    }
                }
                .buttonStyle(.ton(.primary))
                .disabled(viewModel.pin.count < 4)
                .padding(.horizontal, 16)
            }
        }
    }
}
