import SwiftUI
import TONWalletKit

struct StakingView: View {
    @StateObject var viewModel: StakingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: AppSpacing.spacing(4)) {
                    stakingTabSection
                    stakedBalanceSection
                    poolInfoSection
                    errorBanner
                }
                .padding(AppSpacing.spacing(4))
            }

            if viewModel.currentQuote == nil {
                actionButton
            }
        }
        .background(Color.TON.gray100)
        .navigationTitle("Staking")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Staking Tab Section

    private var stakingTabSection: some View {
        VStack(spacing: AppSpacing.spacing(4)) {
            directionPicker

            amountInput

            if viewModel.direction == .unstake {
                unstakeMethodPicker
            }

            if let receiveAmount = viewModel.receiveAmount {
                receiveRow(amount: receiveAmount)
            }

            if viewModel.currentQuote != nil {
                confirmButtons
            }
        }
        .widget()
    }

    private var directionPicker: some View {
        Picker("Direction", selection: Binding(
            get: { viewModel.direction },
            set: { viewModel.setDirection($0) }
        )) {
            Text("Stake").tag(TONStakingQuoteDirection.stake)
            Text("Unstake").tag(TONStakingQuoteDirection.unstake)
        }
        .pickerStyle(.segmented)
    }

    private var amountInput: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing(2)) {
            Text(viewModel.direction == .stake ? "Amount to Stake" : "Amount to Unstake")
                .textSM(weight: .medium)
                .foregroundColor(Color.TON.gray900)

            HStack(spacing: AppSpacing.spacing(3)) {
                TextField("0.0", text: Binding(
                    get: { viewModel.amount },
                    set: { viewModel.setAmount($0) }
                ))
                .keyboardType(.decimalPad)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(Color.TON.gray900)

                Text(viewModel.inputTokenSymbol)
                    .textBase(weight: .medium)
                    .foregroundColor(Color.TON.gray500)
            }
            .padding(AppSpacing.spacing(3))
            .background(Color.TON.gray100)
            .cornerRadius(AppRadius.standard)
        }
    }

    // MARK: - Unstake Method

    private var unstakeMethodPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing(2)) {
            Text("Unstake Method")
                .textSM(weight: .medium)
                .foregroundColor(Color.TON.gray900)

            HStack(spacing: AppSpacing.spacing(2)) {
                ForEach(viewModel.supportedModes, id: \.self) { mode in
                    unstakeModeButton(mode)
                }
            }

            Text(unstakeModeDescription)
                .textXS()
                .foregroundColor(Color.TON.blue600)
                .italic()
        }
    }

    private func unstakeModeButton(_ mode: TONUnstakeMode) -> some View {
        let isSelected = viewModel.unstakeMode == mode
        return Button(unstakeModeLabel(mode)) {
            viewModel.setUnstakeMode(mode)
        }
        .textSM(weight: .medium)
        .foregroundColor(isSelected ? Color.TON.white : Color.TON.gray700)
        .padding(.horizontal, AppSpacing.spacing(3))
        .padding(.vertical, AppSpacing.spacing(2))
        .background(isSelected ? Color.TON.blue600 : Color.TON.white)
        .cornerRadius(AppRadius.standard)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.standard)
                .stroke(isSelected ? Color.clear : Color.TON.gray300, lineWidth: 1)
        )
    }

    private func unstakeModeLabel(_ mode: TONUnstakeMode) -> String {
        switch mode {
        case .instant: return "Instant"
        case .whenAvailable: return "When available"
        case .roundEnd: return "Round end"
        }
    }

    private var unstakeModeDescription: String {
        switch viewModel.unstakeMode {
        case .instant: return "Receive TON immediately"
        case .whenAvailable: return "Receive when liquidity available"
        case .roundEnd: return "Wait for round end, best rate"
        }
    }

    // MARK: - Receive Row

    private func receiveRow(amount: String) -> some View {
        HStack {
            Text("You will receive")
                .textSM()
                .foregroundColor(Color.TON.blue600)
            Spacer()
            Text("\(amount) \(viewModel.receiveTokenSymbol)")
                .textSM(weight: .semibold)
                .foregroundColor(Color.TON.blue600)
        }
        .padding(AppSpacing.spacing(3))
        .background(Color.TON.blue50)
        .cornerRadius(AppRadius.standard)
    }

    // MARK: - Confirm Buttons

    private var confirmButtons: some View {
        HStack(spacing: AppSpacing.spacing(3)) {
            Button("Cancel") {
                viewModel.cancelQuote()
            }
            .buttonStyle(TONLegacyButtonStyle(type: .secondary))

            Button(viewModel.buttonTitle) {
                viewModel.executeStake()
            }
            .buttonStyle(TONLegacyButtonStyle(type: .primary, isLoading: viewModel.isExecuting))
            .disabled(viewModel.isExecuting)
        }
    }

    // MARK: - Staked Balance

    @ViewBuilder
    private var stakedBalanceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing(3)) {
            Text("Your Stake")
                .textLG(weight: .semibold)
                .foregroundColor(Color.TON.gray900)

            Divider()

            VStack(alignment: .leading, spacing: AppSpacing.spacing(1)) {
                Text("Balance")
                    .textSM()
                    .foregroundColor(Color.TON.gray500)
                Text("\(viewModel.formattedStakedBalance ?? "0") tsTON")
                    .text2XL(weight: .bold)
                    .foregroundColor(Color.TON.gray900)
            }
        }
        .widget()
    }

    // MARK: - Pool Info

    @ViewBuilder
    private var poolInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing(3)) {
            Text("Pool Info")
                .textLG(weight: .semibold)
                .foregroundColor(Color.TON.gray900)

            Divider()

            infoRow(label: "Provider", value: "Tonstakers")
            if let apy = viewModel.formattedAPY {
                infoRow(label: "APY", value: apy, valueColor: Color.TON.green600)
            }
            if let available = viewModel.formattedInstantUnstakeAvailable {
                infoRow(label: "Instant Unstake Available", value: "\(available) TON")
            }
        }
        .widget()
    }

    private func infoRow(label: String, value: String, valueColor: Color = Color.TON.gray900) -> some View {
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
                isLoading: viewModel.isLoadingQuote
            ))
            .disabled(!viewModel.canGetQuote)
            .padding(.horizontal, AppSpacing.spacing(4))
            .padding(.bottom, AppSpacing.spacing(4))
        }
        .background(Color.TON.white)
    }
}
