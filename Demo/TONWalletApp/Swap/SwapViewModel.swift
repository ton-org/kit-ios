import Foundation
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

    let wallet: any TONWalletProtocol

    private var swapManager: TONSwapManagerProtocol?

    init(wallet: any TONWalletProtocol) {
        self.wallet = wallet
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
}
