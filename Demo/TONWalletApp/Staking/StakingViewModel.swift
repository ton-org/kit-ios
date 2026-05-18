import Foundation
import Combine
import TONWalletKit

@MainActor
class StakingViewModel: ObservableObject {
    @Published var amount = ""
    @Published var direction: TONStakingQuoteDirection = .stake
    @Published var unstakeMode: TONUnstakeMode = .instant
    @Published var currentQuote: TONStakingQuote?
    @Published var isLoadingQuote = false
    @Published var isExecuting = false
    @Published var error: String?
    @Published var stakedBalance: TONStakingBalance?
    @Published var providerInfo: TONStakingProviderInfo?
    @Published var supportedModes: [TONUnstakeMode] = [.instant, .whenAvailable, .roundEnd]

    let wallet: any TONWalletProtocol

    private var stakingManager: TONStakingManagerProtocol?
    private let formatter = TONTokenAmountFormatter()

    init(wallet: any TONWalletProtocol) {
        self.wallet = wallet
    }

    var inputTokenSymbol: String {
        direction == .stake ? "TON" : "tsTON"
    }

    var receiveTokenSymbol: String {
        direction == .stake ? "tsTON" : "TON"
    }

    var receiveAmount: String? {
        currentQuote?.amountOut
    }

    var canGetQuote: Bool {
        !amount.isEmpty && Double(amount) ?? 0 > 0 && !isLoadingQuote
    }

    var buttonTitle: String {
        if currentQuote != nil {
            return direction == .stake ? "Confirm Stake" : "Confirm Unstake"
        }
        return direction == .stake ? "Preview Stake" : "Preview Unstake"
    }

    var formattedAPY: String? {
        providerInfo.flatMap { String(format: "%.2f%%", $0.apy) }
    }

    var formattedStakedBalance: String? {
        stakedBalance?.stakedBalance
    }

    var formattedInstantUnstakeAvailable: String? {
        providerInfo?.instantUnstakeAvailable
    }
    
    private var subscribers = Set<AnyCancellable>()

    func setAmount(_ value: String) {
        guard value.isEmpty || Double(value) != nil else { return }
        amount = value
        clearQuote()
    }

    func setDirection(_ newDirection: TONStakingQuoteDirection) {
        direction = newDirection
        amount = ""
        clearQuote()
    }

    func setUnstakeMode(_ mode: TONUnstakeMode) {
        unstakeMode = mode
        clearQuote()
    }

    func getQuote() {
        guard canGetQuote else { return }

        isLoadingQuote = true
        error = nil

        Task {
            do {
                let manager = try await getStakingManager()
                let amountValue = amount

                let quote = try await manager.quote(params: TONStakingQuoteParams<AnyCodable>(
                    direction: direction,
                    amount: amountValue,
                    userAddress: wallet.address,
                    network: TONNetwork.mainnet,
                    unstakeMode: direction == .unstake ? unstakeMode : nil
                ))

                currentQuote = quote
            } catch {
                self.error = error.localizedDescription
            }
            isLoadingQuote = false
        }
    }

    func executeStake() {
        guard let currentQuote, !isExecuting else { return }

        isExecuting = true
        error = nil

        Task {
            do {
                let manager = try await getStakingManager()
                let tx = try await manager.stakeTransaction(params: TONStakeParams<AnyCodable>(
                    quote: currentQuote,
                    userAddress: wallet.address
                ))

                _ = try await wallet.send(transactionRequest: tx)
                clearQuote()
                amount = ""
                await loadStakingData()
            } catch {
                self.error = error.localizedDescription
            }
            isExecuting = false
        }
    }

    func buttonAction() {
        if currentQuote != nil {
            executeStake()
        } else {
            getQuote()
        }
    }

    func cancelQuote() {
        clearQuote()
    }

    func load() async {
        do {
            try await subscribeToBalanceChanges()
            _ = try await getStakingManager()
            await loadStakingData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadStakingData() async {
        guard let manager = stakingManager else { return }
        
        do {
            async let balanceTask = manager.stakedBalance(
                userAddress: wallet.address,
                network: TONNetwork.mainnet
            )
            async let infoTask = manager.stakingProviderInfo(
                network: TONNetwork.mainnet
            )

            let (balance, info) = try await (balanceTask, infoTask)
            stakedBalance = balance
            providerInfo = info
        } catch {
            debugPrint("Failed to load staking data: \(error.localizedDescription)")
        }
    }
    
    func updateBalance() {
        guard let manager = stakingManager else { return }
        
        Task {
            let balance = try await manager.stakedBalance(
                userAddress: wallet.address,
                network: TONNetwork.mainnet
            )
            self.stakedBalance = balance
        }
    }

    private func clearQuote() {
        currentQuote = nil
        error = nil
    }

    private func getStakingManager() async throws -> TONStakingManagerProtocol {
        if let stakingManager { return stakingManager }
        let kit = await TONWalletKit.shared()
        let manager = try await kit.staking()
        let provider = try await kit.stakingProvider(config: TONTonStakersProviderConfig())
        try manager.register(provider: provider)
        try manager.set(defaultProviderId: provider.identifier)

        if let modes = try? manager.supportedUnstakeModes() {
            supportedModes = modes
        }

        stakingManager = manager
        return manager
    }
    
    private func subscribeToBalanceChanges() async throws {
        try await TONWalletKit.shared().streaming().jettons(network: .mainnet, address: wallet.address.value)
            .receive(on: DispatchQueue.main)
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] balance in
                    if balance.status == .finalized {
                        self?.updateBalance()
                    }
                }
            )
            .store(in: &subscribers)
    }
}
