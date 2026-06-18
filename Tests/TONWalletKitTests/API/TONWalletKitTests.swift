import Testing
import Foundation
@testable import TONWalletKit

@Suite("TONWalletKit Tests")
struct TONWalletKitTests {

    private let testAddress: TONUserFriendlyAddress = {
        let hash = Data(repeating: 0xab, count: 32)
        return TONRawAddress(workchain: 0, hash: hash).userFriendly(isBounceable: true)
    }()

    private func makeConfiguration() -> TONWalletKitConfiguration {
        TONWalletKitConfiguration(
            networkConfigurations: [
                TONWalletKitConfiguration.NetworkConfiguration(
                    network: .mainnet,
                    apiClientConfiguration: TONWalletKitConfiguration.APIClientConfiguration(key: "test-key")
                )
            ],
            walletManifest: TONWalletKitConfiguration.Manifest(
                name: "Test",
                appName: "TestApp",
                imageUrl: "https://example.com/icon.png",
                aboutUrl: "https://example.com",
                universalLink: "https://example.com/tonconnect",
                bridgeUrl: "https://bridge.example.com"
            ),
            storage: .memory,
            bridge: nil,
            features: []
        )
    }

    private func makeSUT(
        shouldThrow: Bool = false
    ) -> (sut: TONWalletKit, provider: MockContextProvider, context: MockWalletKitContext) {
        let provider = MockContextProvider()
        let mockContext = MockWalletKitContext()
        provider.mockContext = mockContext
        provider.shouldThrow = shouldThrow
        let sut = TONWalletKit(
            configuration: makeConfiguration(),
            contextProvider: provider
        )
        return (sut, provider, mockContext)
    }

    @Test("isInitialized false before init")
    func isInitializedFalseBeforeInit() {
        let (sut, _, _) = makeSUT()

        #expect(sut.isInitialized == false)
    }

    @Test("initialize() calls context provider")
    func initializeCallsContextProvider() async throws {
        let (sut, provider, _) = makeSUT()

        try await sut.initialize()

        #expect(provider.contextCallCount == 1)
    }

    @Test("initialize() sets isInitialized true")
    func initializeSetsIsInitialized() async throws {
        let (sut, _, _) = makeSUT()

        try await sut.initialize()

        #expect(sut.isInitialized == true)
    }

    @Test("initialize() twice only calls provider once")
    func initializeTwiceOnlyOneCall() async throws {
        let (sut, provider, _) = makeSUT()

        try await sut.initialize()
        try await sut.initialize()

        #expect(provider.contextCallCount == 1)
    }

    @Test("initialize() with throwing provider throws")
    func initializeThrowingProviderThrows() async {
        let (sut, _, _) = makeSUT(shouldThrow: true)

        await #expect(throws: (any Error).self) {
            try await sut.initialize()
        }
    }

    @Test("signer(mnemonic:) calls createSignerFromMnemonic")
    func signerMnemonicCallsCreate() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()
        let mnemonic = TONMnemonic(value: (1...24).map { "word\($0)" })

        _ = try? await sut.signer(mnemonic: mnemonic)

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.createSignerFromMnemonic"))
    }

    @Test("signer(privateKey:) calls createSignerFromPrivateKey")
    func signerPrivateKeyCallsCreate() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()

        _ = try? await sut.signer(privateKey: Data([0x01, 0x02]))

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.createSignerFromPrivateKey"))
    }

    @Test("walletV4R2Adapter() calls createV4R2WalletAdapter")
    func walletV4R2AdapterCalls() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()
        let signer = MockSigner()
        let params = TONV4R2WalletParameters(network: .mainnet, domain: nil)

        _ = try? await sut.walletV4R2Adapter(signer: signer, parameters: params)

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.createV4R2WalletAdapter"))
    }

    @Test("walletV5R1Adapter() calls createV5R1WalletAdapter")
    func walletV5R1AdapterCalls() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()
        let signer = MockSigner()
        let params = TONV5R1WalletParameters(network: .mainnet, domain: nil)

        _ = try? await sut.walletV5R1Adapter(signer: signer, parameters: params)

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.createV5R1WalletAdapter"))
    }

    @Test("add(walletAdapter:) calls addWallet")
    func addWalletAdapterCallsAddWallet() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()
        let adapter = MockWalletAdapter()

        _ = try? await sut.add(walletAdapter: adapter)

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.addWallet"))
    }

    @Test("wallet(id:) calls getWallet")
    func walletIdCallsGetWallet() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()

        _ = try? await sut.wallet(id: "wallet-1")

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.getWallet"))
    }

    @Test("wallets() calls getWallets")
    func walletsCallsGetWallets() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()

        _ = try? await sut.wallets()

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.getWallets"))
    }

    @Test("connect(url:) calls handleTonConnectUrl")
    func connectUrlCallsHandleTonConnectUrl() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()

        try? await sut.connect(url: "tc://example.com")

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.handleTonConnectUrl"))
    }

    @Test("connect(url:) adds tc:// scheme if missing")
    func connectUrlAddsScheme() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()

        try? await sut.connect(url: "example.com/connect")

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.handleTonConnectUrl"))
    }

    @Test("remove(walletId:) calls removeWallet")
    func removeWalletIdCallsRemoveWallet() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()

        try? await sut.remove(walletId: "wallet-1")

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.removeWallet"))
    }

    @Test("injectableBridge() before init throws")
    func injectableBridgeBeforeInitThrows() {
        let (sut, _, _) = makeSUT()

        #expect(throws: (any Error).self) {
            try sut.injectableBridge()
        }
    }

    @Test("injectableBridge() after init returns bridge")
    func injectableBridgeAfterInitReturnsBridge() async throws {
        let (sut, _, _) = makeSUT()
        try await sut.initialize()

        let bridge = try sut.injectableBridge()

        #expect(type(of: bridge) == TONWalletKitInjectableBridge.self)
    }

    @Test("send(transaction:from:) calls sendTransaction")
    func sendTransactionFromWalletCalls() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()
        let walletMock = MockJSDynamicObject()
        let wallet = TONWallet(jsWallet: walletMock, id: "w1", address: testAddress, client: MockAPIClient())
        let transaction = TONTransactionRequest(messages: [])

        try? await sut.send(transaction: transaction, from: wallet)

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.sendTransaction"))
    }

    @Test("add(eventsHandler:) before init adds to pending")
    func addEventsHandlerBeforeInitPending() throws {
        let (sut, _, _) = makeSUT()
        let handler = MockTONBridgeEventsHandler()

        try sut.add(eventsHandler: handler)

        #expect(sut.isInitialized == false)
    }

    @Test("add(eventsHandler:) after init registers handler")
    func addEventsHandlerAfterInit() async throws {
        let (sut, _, _) = makeSUT()
        try await sut.initialize()
        let handler = MockTONBridgeEventsHandler()

        try sut.add(eventsHandler: handler)

        try sut.add(eventsHandler: handler)
    }

    @Test("remove(eventsHandler:) removes handler")
    func removeEventsHandler() async throws {
        let (sut, _, _) = makeSUT()
        try await sut.initialize()
        let handler = MockTONBridgeEventsHandler()

        try sut.add(eventsHandler: handler)
        try sut.remove(eventsHandler: handler)
    }

    @Test("jsWalletKit() auto-initializes when not initialized")
    func jsWalletKitAutoInitializes() async throws {
        let (sut, provider, _) = makeSUT()

        _ = try? await sut.jsWalletKit()

        #expect(provider.contextCallCount == 1)
    }

    @Test("omnistonSwapProvider(config:) calls createOmnistonSwapProvider")
    func omnistonSwapProviderCalls() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()

        _ = try? await sut.omnistonSwapProvider(config: nil)

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.createOmnistonSwapProvider"))
    }

    @Test("deDustSwapProvider(config:) calls createDeDustSwapProvider")
    func deDustSwapProviderCalls() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()

        _ = try? await sut.dedustSwapProvider(config: nil)

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.createDeDustSwapProvider"))
    }

    @Test("swap() calls swap")
    func swapCallsSwap() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()

        _ = try? await sut.swap()

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.swap"))
    }

    @Test("streaming() calls streaming")
    func streamingCallsStreaming() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()

        _ = try? await sut.streaming()

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.streaming"))
    }

    @Test("tonApiGaslessProvider(config:) calls createTonApiGaslessProvider")
    func tonApiGaslessProviderCalls() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()

        _ = try? await sut.tonApiGaslessProvider(config: nil)

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.createTonApiGaslessProvider"))
    }

    @Test("gasless() calls gasless")
    func gaslessCallsGasless() async throws {
        let (sut, _, mockContext) = makeSUT()
        try await sut.initialize()

        _ = try? await sut.gasless()

        let paths = mockContext.callRecords.map(\.path)
        #expect(paths.contains("walletKit.gasless"))
    }
}
