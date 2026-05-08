import SwiftUI
import TONWalletKit

struct SwapView: View {
    @StateObject var viewModel: SwapViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: AppSpacing.spacing(4)) {
                    tokenInputSection
                    providerPicker
                    destinationSection
                    quoteInfoSection
                    errorBanner
                }
                .padding(AppSpacing.spacing(4))
            }

            actionButton
        }
        .background(Color.TON.gray100)
        .navigationTitle("Swap")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.showSettings = true }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(Color.TON.gray600)
                }
            }
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SwapSettingsView(
                slippageBps: $viewModel.slippageBps,
                isPresented: $viewModel.showSettings
            )
            .presentationDetents([.medium])
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Token Input Section

    private var tokenInputSection: some View {
        VStack(spacing: 0) {
            fromSection
                .widget()

            swapDirectionButton

            toSection
                .widget()
        }
    }

    private var fromSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing(2)) {
            HStack {
                Text("From")
                    .textSM()
                    .foregroundColor(Color.TON.gray500)
                Spacer()
                Text("Balance: \(viewModel.wallet.formattedTONBalance ?? "—")")
                    .textSM()
                    .foregroundColor(Color.TON.gray500)
            }

            HStack(spacing: AppSpacing.spacing(3)) {
                TextField("0", text: Binding(
                    get: { viewModel.fromAmount },
                    set: { viewModel.setFromAmount($0) }
                ))
                .keyboardType(.decimalPad)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(Color.TON.gray900)

                tokenBadge(symbol: viewModel.fromTokenSymbol)
            }

            HStack {
                Spacer()
                Button("Max") {
                    viewModel.setFromAmount(viewModel.wallet.formattedTONBalance ?? "0")
                }
                .textSM(weight: .medium)
                .foregroundColor(Color.TON.blue600)
                .padding(.horizontal, AppSpacing.spacing(3))
                .padding(.vertical, AppSpacing.spacing(1.5))
                .background(Color.TON.blue50)
                .cornerRadius(AppRadius.standard / 2)
            }
        }
    }

    private var swapDirectionButton: some View {
        Button(action: { viewModel.swapTokens() }) {
            Image(systemName: "arrow.up.arrow.down")
                .textLG(weight: .semibold)
                .foregroundColor(Color.TON.blue600)
                .frame(width: 40, height: 40)
                .background(Color.TON.white)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
        }
        .padding(.vertical, -AppSpacing.spacing(2))
        .zIndex(1)
    }

    private var toSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing(2)) {
            HStack {
                Text("To")
                    .textSM()
                    .foregroundColor(Color.TON.gray500)
                Spacer()
                Text("Balance: 0.000000")
                    .textSM()
                    .foregroundColor(Color.TON.gray500)
            }

            HStack(spacing: AppSpacing.spacing(3)) {
                if viewModel.isReverseSwap {
                    TextField("0", text: Binding(
                        get: { viewModel.toAmount },
                        set: { viewModel.setToAmount($0) }
                    ))
                    .keyboardType(.decimalPad)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(Color.TON.gray900)
                } else {
                    Text(viewModel.toAmount.isEmpty ? "0" : viewModel.toAmount)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(viewModel.toAmount.isEmpty ? Color.TON.gray400 : Color.TON.gray900)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                tokenBadge(symbol: viewModel.toTokenSymbol)
            }
        }
    }

    private func tokenBadge(symbol: String) -> some View {
        HStack(spacing: AppSpacing.spacing(1.5)) {
            Circle()
                .fill(Color.TON.blue100)
                .frame(width: 28, height: 28)
                .overlay(
                    Text(String(symbol.prefix(1)))
                        .textXS(weight: .bold)
                        .foregroundColor(Color.TON.blue600)
                )
            Text(symbol)
                .textBase(weight: .medium)
                .foregroundColor(Color.TON.gray900)
        }
        .padding(.horizontal, AppSpacing.spacing(3))
        .padding(.vertical, AppSpacing.spacing(2))
        .background(Color.TON.gray100)
        .cornerRadius(AppRadius.standard)
    }

    // MARK: - Provider Picker

    private var providerPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing(2)) {
            Text("Provider")
                .textSM(weight: .medium)
                .foregroundColor(Color.TON.gray500)

            if let provider = viewModel.selectedProvider {
                Picker("Provider", selection: Binding(
                    get: { provider },
                    set: { viewModel.setProvider($0) }
                )) {
                    ForEach(viewModel.providers) { option in
                        Text(option.name).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .widget()
    }

    // MARK: - Destination

    private var destinationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing(2)) {
            Toggle(isOn: $viewModel.useCustomDestination) {
                Text("Use different recipient address")
                    .textSM()
                    .foregroundColor(Color.TON.gray700)
            }
            .toggleStyle(CheckboxToggleStyle())

            if viewModel.useCustomDestination {
                TextField("EQxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", text: $viewModel.destinationAddress)
                    .textFieldStyle(TONTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.top, AppSpacing.spacing(1))
            }
        }
        .padding(.horizontal, AppSpacing.spacing(1))
    }

    // MARK: - Quote Info

    @ViewBuilder
    private var quoteInfoSection: some View {
        if let quote = viewModel.currentQuote {
            VStack(spacing: AppSpacing.spacing(3)) {
                if let expiresAt = quote.expiresAt {
                    QuoteTimerView(expiresAt: expiresAt) {
                        viewModel.getQuote()
                    }
                }

                Divider()

                quoteRow(label: "Provider", value: quote.providerId.capitalized)

                quoteRow(
                    label: "Minimum Received",
                    value: "\(quote.minReceived) \(quote.toToken.symbol ?? "")"
                )

                quoteRow(label: "Slippage", value: "\(viewModel.slippageBps / 100)%")

                if let impact = quote.priceImpact {
                    let impactText = String(format: "%.2f%%", Double(impact) / 100.0)
                    quoteRow(label: "Price Impact", value: impactText, valueColor: priceImpactColor)
                }
            }
            .widget()
        }
    }

    private var priceImpactColor: Color {
        switch viewModel.priceImpactColor {
        case .low: return Color.TON.green600
        case .medium: return Color.TON.yellow600
        case .high: return Color.TON.red600
        }
    }

    private func quoteRow(label: String, value: String, valueColor: Color = Color.TON.gray900) -> some View {
        HStack {
            Text(label)
                .textSM()
                .foregroundColor(Color.TON.gray500)
            Spacer()
            Text(value)
                .textSM(weight: .medium)
                .foregroundColor(valueColor)
        }
    }

    // MARK: - Error

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.error {
            Text(error)
                .textSM()
                .foregroundColor(Color.TON.red600)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.spacing(3))
                .background(Color.TON.red50)
                .cornerRadius(AppRadius.standard)
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        VStack {
            Divider()

            Button(viewModel.buttonTitle) {
                viewModel.buttonAction()
            }
            .buttonStyle(TONLegacyButtonStyle(
                type: .primary,
                isLoading: viewModel.isLoadingQuote || viewModel.isSwapping
            ))
            .disabled(!viewModel.canGetQuote && viewModel.currentQuote == nil)
            .padding(.horizontal, AppSpacing.spacing(4))
            .padding(.bottom, AppSpacing.spacing(4))
        }
        .background(Color.TON.white)
    }

    // MARK: - Helpers

}

// MARK: - Checkbox Toggle Style

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack(spacing: AppSpacing.spacing(2)) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? Color.TON.blue600 : Color.TON.gray400)
                    .textLG()
                configuration.label
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Wallet balance helper

private extension TONWalletProtocol {
    var formattedTONBalance: String? {
        nil
    }
}
