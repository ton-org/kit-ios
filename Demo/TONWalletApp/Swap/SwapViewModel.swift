import Foundation
import Combine
import TONWalletKit

struct SwapProviderOption: Identifiable, Hashable, Equatable {
    let name: String
    let identifier: any TONSwapProviderIdentifier

    var id: String { identifier.name }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
class SwapViewModel: ObservableObject {
    @Published var fromToken = TONSwapToken(address: "ton", decimals: 9, name: "GRAM", symbol: "GRAM")
    @Published var toToken = TONSwapToken(address: "EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs", decimals: 6, name: "USDT", symbol: "USDT")
    @Published var fromAmount = ""
    @Published var toAmount = ""
    @Published var isReverseSwap = false
    @Published var providers: [SwapProviderOption] = []
    @Published var selectedProvider: SwapProviderOption?
    @Published var currentQuote: TONSwapQuote?
    @Published var isLoadingQuote = false
    @Published var isSwapping = false
    @Published var error: String?
    @Published var slippageBps: Int = 100
    @Published var destinationAddress = ""
    @Published var showSettings = false
    @Published var useCustomDestination = false

    /// Formatted balances of the currently selected from/to tokens, kept live via streaming.
    @Published private(set) var fromBalance: String?
    @Published private(set) var toBalance: String?

    let wallet: any TONWalletProtocol

    private var swapManager: TONSwapManagerProtocol?

    /// Streamed TON balance (already human-readable) and raw jetton balances keyed by the
    /// canonical raw master address (`workchain:hash`), formatted per-token on demand.
    private var tonBalance: String?
    private var jettonRawBalances: [String: TONTokenAmount] = [:]
    private var balanceSubscribers = Set<AnyCancellable>()

    init(wallet: any TONWalletProtocol) {
        self.wallet = wallet
        subscribeToBalances()
    }

    var fromTokenSymbol: String { fromToken.symbol ?? "???" }
    var toTokenSymbol: String { toToken.symbol ?? "???" }

    var canGetQuote: Bool {
        !fromAmount.isEmpty && Double(fromAmount) ?? 0 > 0 && !isLoadingQuote
    }

    var canSwap: Bool {
        currentQuote != nil && !isSwapping && !isLoadingQuote
    }

    var buttonTitle: String {
        if currentQuote != nil {
            return "Swap \(fromTokenSymbol) for \(toTokenSymbol)"
        }
        return "Get Quote"
    }

    var priceImpactColor: PriceImpactLevel {
        guard let impact = currentQuote?.priceImpact else { return .low }
        if impact > 500 { return .high }
        if impact > 200 { return .medium }
        return .low
    }

    enum PriceImpactLevel {
        case low, medium, high
    }

    func setFromAmount(_ value: String) {
        guard value.isEmpty || Double(value) != nil else { return }
        fromAmount = value
        isReverseSwap = false
        clearQuote()
    }

    func setToAmount(_ value: String) {
        guard value.isEmpty || Double(value) != nil else { return }
        toAmount = value
        isReverseSwap = true
        clearQuote()
    }

    func setProvider(_ provider: SwapProviderOption) {
        selectedProvider = provider
        clearQuote()
        
        Task {
            do {
                try await getSwapManager().set(defaultProviderId: provider.identifier)
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    func swapTokens() {
        let temp = fromToken
        fromToken = toToken
        toToken = temp
        fromAmount = ""
        toAmount = ""
        clearQuote()
        refreshDisplayedBalances()
    }

    func getQuote() {
        let amount = isReverseSwap ? toAmount : fromAmount
        guard !amount.isEmpty, let amountDouble = Double(amount), amountDouble > 0 else { return }

        isLoadingQuote = true
        error = nil

        Task {
            do {
                let manager = try await getSwapManager()
                let quote: TONSwapQuote
                
                quote = try await manager.quote(params: TONSwapQuoteParams<AnyCodable>(
                    amount: amount,
                    from: fromToken,
                    to: toToken,
                    network: TONNetwork.mainnet,
                    slippageBps: slippageBps,
                    maxOutgoingMessages: 4,
                    isReverseSwap: isReverseSwap
                ))
                
                currentQuote = quote
                
                if isReverseSwap {
                    fromAmount = quote.fromAmount
                } else {
                    toAmount = quote.toAmount
                }
            } catch {
                self.error = error.localizedDescription
            }
            isLoadingQuote = false
        }
    }

    func executeSwap() {
        guard let currentQuote, !isSwapping else { return }

        isSwapping = true
        error = nil

        Task {
            do {
                let manager = try await getSwapManager()
                let dest = useCustomDestination && !destinationAddress.isEmpty
                    ? try TONUserFriendlyAddress(value: destinationAddress)
                    : nil

                let tx = try await manager.swapTransaction(params: TONSwapParams<AnyCodable>(
                    quote: currentQuote,
                    userAddress: wallet.address,
                    destinationAddress: dest
                ))
               
                try await TONWalletKit.shared().send(transaction: tx, from: wallet)
                clearQuote()
                fromAmount = ""
                toAmount = ""
            } catch {
                self.error = error.localizedDescription
            }
            isSwapping = false
        }
    }

    func buttonAction() {
        if currentQuote != nil {
            executeSwap()
        } else {
            getQuote()
        }
    }
    
    func load() async {
        do {
            _ = try await getSwapManager()
        } catch {
            debugPrint(error.localizedDescription)
        }
        await loadInitialBalances()
    }

    private func clearQuote() {
        currentQuote = nil
        error = nil
    }

    private func getSwapManager() async throws -> TONSwapManagerProtocol {
        if let swapManager { return swapManager }
        let kit = await TONWalletKit.shared()
        let manager = try await kit.swap()

        let omniston = try await kit.omnistonSwapProvider(config: nil)
        try manager.register(provider: omniston)
        
        let deDust = try await kit.dedustSwapProvider(config: nil)
        try manager.register(provider: deDust)

        try manager.set(defaultProviderId: omniston.identifier)

        self.providers = [
            SwapProviderOption(name: "Omniston", identifier: omniston.identifier),
            SwapProviderOption(name: "DeDust", identifier: deDust.identifier),
        ]
        
        selectedProvider = providers.first

        swapManager = manager
        return manager
    }

    // MARK: - Balances (initial fetch + streaming)

    /// Seeds the from/to balances once. Streaming only pushes on change, so without this the
    /// balances stay empty until the wallet's balance actually moves.
    private func loadInitialBalances() async {
        if let ton = try? await wallet.balance() {
            let formatter = TONBalanceFormatter()
            formatter.nanoUnitDecimalsNumber = 9
            tonBalance = formatter.string(from: ton)
        }

        for token in [fromToken, toToken] where !Self.isNativeTON(token.address) {
            guard let address = try? TONUserFriendlyAddress(value: token.address) else { continue }
            if let balance = try? await wallet.jettonBalance(jettonAddress: address) {
                jettonRawBalances[address.raw.string] = balance
            }
        }

        refreshDisplayedBalances()
    }

    private func subscribeToBalances() {
        let address = wallet.address.value
        Task { [weak self] in
            do {
                let streaming = try await TONWalletKit.shared().streaming()
                guard let self else { return }

                streaming.balance(network: .mainnet, address: address)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { [weak self] update in
                            guard let self, update.status == .finalized else { return }
                            self.tonBalance = update.balance
                            self.refreshDisplayedBalances()
                        }
                    )
                    .store(in: &self.balanceSubscribers)

                streaming.jettons(network: .mainnet, address: address)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { [weak self] update in
                            guard let self, update.status == .finalized else { return }
                            self.jettonRawBalances[update.masterAddress.raw.string] = update.rawBalance
                            self.refreshDisplayedBalances()
                        }
                    )
                    .store(in: &self.balanceSubscribers)
            } catch {
                debugPrint("Failed to subscribe to swap balance streams: \(error)")
            }
        }
    }

    private func refreshDisplayedBalances() {
        fromBalance = formattedBalance(for: fromToken)
        toBalance = formattedBalance(for: toToken)
    }

    private func formattedBalance(for token: TONSwapToken) -> String? {
        if Self.isNativeTON(token.address) {
            return tonBalance
        }
        guard
            let key = Self.rawKey(for: token.address),
            let raw = jettonRawBalances[key]
        else {
            return nil
        }
        let formatter = TONBalanceFormatter()
        formatter.nanoUnitDecimalsNumber = Int(token.decimals)
        return formatter.string(from: raw)
    }

    private static func isNativeTON(_ address: String) -> Bool {
        address.lowercased() == "ton"
    }

    /// Canonical `workchain:hash` key for a jetton master address, so streamed addresses match
    /// regardless of bounceable / URL-safe formatting.
    private static func rawKey(for address: String) -> String? {
        (try? TONUserFriendlyAddress(value: address))?.raw.string
    }
}
