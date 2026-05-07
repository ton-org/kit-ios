import Testing
import JavaScriptCore
@testable import TONWalletKit
import _BigInt

@Suite("TONSwapManager Tests")
struct TONSwapManagerTests {

    private func makeSUT() -> (sut: TONSwapManager, mock: MockJSDynamicObject) {
        let mock = MockJSDynamicObject()
        let sut = TONSwapManager(jsObject: mock)
        return (sut, mock)
    }

    private func makeProvider() -> TONSwapProvider<TONOmnistonSwapProviderIdentifier> {
        let providerMock = MockJSDynamicObject()
        let identifier = TONOmnistonSwapProviderIdentifier(name: "omniston")
        return TONSwapProvider(jsObject: providerMock, identifier: identifier)
    }

    private func makeQuoteParams() -> TONSwapQuoteParams<TONOmnistonProviderOptions> {
        TONSwapQuoteParams(
            amount: "1.0",
            from: TONSwapToken(address: "ton", decimals: 9, name: "TON", symbol: "TON"),
            to: TONSwapToken(address: "EQUSDT", decimals: 6, name: "USDT", symbol: "USDT"),
            network: TONNetwork(chainId: "-239")
        )
    }

    private func makeSwapParams() -> TONSwapParams<AnyCodable> {
        let token = TONSwapToken(address: "ton", decimals: 9, name: "TON", symbol: "TON")
        let quote = TONSwapQuote(
            fromToken: token,
            toToken: token,
            rawFromAmount: TONTokenAmount(nanoUnits: BigInt(stringLiteral: "1000000000")),
            rawToAmount: TONTokenAmount(nanoUnits: BigInt(stringLiteral: "1000000")),
            fromAmount: "1",
            toAmount: "1",
            rawMinReceived: TONTokenAmount(nanoUnits: BigInt(stringLiteral: "990000")),
            minReceived: "0.99",
            network: TONNetwork(chainId: "-239"),
            providerId: "omniston"
        )
        let hash = Data(repeating: 0xab, count: 32)
        let address = TONRawAddress(workchain: 0, hash: hash).userFriendly(isBounceable: true)
        return TONSwapParams(quote: quote, userAddress: address)
    }

    @Test("register(provider:) calls registerProvider on jsObject")
    func registerCallsRegisterProvider() throws {
        let (sut, mock) = makeSUT()

        try sut.register(provider: makeProvider())

        #expect(mock.callRecords.first?.path == "registerProvider")
    }

    @Test("register(provider:) throws when jsObject throws")
    func registerThrowsOnError() {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true

        #expect(throws: (any Error).self) {
            try sut.register(provider: makeProvider())
        }
    }

    @Test("set(defaultProviderId:) calls setDefaultProvider on jsObject")
    func setDefaultProviderIdCallsSetDefaultProvider() throws {
        let (sut, mock) = makeSUT()
        let identifier = TONOmnistonSwapProviderIdentifier(name: "omniston")

        try sut.set(defaultProviderId: identifier)

        #expect(mock.callRecords.first?.path == "setDefaultProvider")
    }

    @Test("set(defaultProviderId:) throws when jsObject throws")
    func setDefaultProviderIdThrowsOnError() {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true
        let identifier = TONOmnistonSwapProviderIdentifier(name: "omniston")

        #expect(throws: (any Error).self) {
            try sut.set(defaultProviderId: identifier)
        }
    }

    @Test("provider(with:) calls getProvider on jsObject")
    func providerCallsGetProvider() throws {
        let (sut, mock) = makeSUT()
        let identifier = TONOmnistonSwapProviderIdentifier(name: "omniston")

        _ = try sut.provider(with: identifier)

        #expect(mock.callRecords.first?.path == "getProvider")
    }

    @Test("provider(with:) throws when jsObject throws")
    func providerThrowsOnError() {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true
        let identifier = TONOmnistonSwapProviderIdentifier(name: "omniston")

        #expect(throws: (any Error).self) {
            try sut.provider(with: identifier)
        }
    }

    @Test("registeredProviders() calls getRegisteredProviders on jsObject")
    func registeredProvidersCallsGetRegisteredProviders() throws {
        let (sut, mock) = makeSUT()
        mock.stubbedResults["getRegisteredProviders"] = ["omniston", "dedust"] as [String]

        let result = try sut.registeredProviders()

        #expect(mock.callRecords.first?.path == "getRegisteredProviders")
        #expect(result.map { $0.name } == ["omniston", "dedust"])
    }

    @Test("registeredProviders() throws when jsObject throws")
    func registeredProvidersThrowsOnError() {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true

        #expect(throws: (any Error).self) {
            try sut.registeredProviders()
        }
    }

    @Test("hasProvider(with:) calls hasProvider on jsObject")
    func hasProviderCallsHasProvider() throws {
        let (sut, mock) = makeSUT()
        mock.stubbedResults["hasProvider"] = true
        let identifier = TONOmnistonSwapProviderIdentifier(name: "omniston")

        let result = try sut.hasProvider(with: identifier)

        #expect(mock.callRecords.first?.path == "hasProvider")
        #expect(result == true)
    }

    @Test("hasProvider(with:) throws when jsObject throws")
    func hasProviderThrowsOnError() {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true
        let identifier = TONOmnistonSwapProviderIdentifier(name: "omniston")

        #expect(throws: (any Error).self) {
            try sut.hasProvider(with: identifier)
        }
    }

    @Test("quote(params:identifier:) calls getQuote on jsObject")
    func quoteCallsGetQuote() async {
        let (sut, mock) = makeSUT()
        let identifier = TONOmnistonSwapProviderIdentifier(name: "omniston")

        _ = try? await sut.quote(params: makeQuoteParams(), identifier: identifier)

        #expect(mock.callRecords.first?.path == "getQuote")
    }

    @Test("quote(params:identifier:) throws when jsObject throws")
    func quoteThrowsOnError() async {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true
        let identifier = TONOmnistonSwapProviderIdentifier(name: "omniston")

        await #expect(throws: (any Error).self) {
            try await sut.quote(params: makeQuoteParams(), identifier: identifier)
        }
    }

    @Test("swapTransaction(params:) calls buildSwapTransaction on jsObject")
    func swapTransactionCallsBuildSwapTransaction() async {
        let (sut, mock) = makeSUT()

        _ = try? await sut.swapTransaction(params: makeSwapParams())

        #expect(mock.callRecords.first?.path == "buildSwapTransaction")
    }

    @Test("swapTransaction(params:) throws when jsObject throws")
    func swapTransactionThrowsOnError() async {
        let (sut, mock) = makeSUT()
        mock.shouldThrowOnCall = true

        await #expect(throws: (any Error).self) {
            try await sut.swapTransaction(params: makeSwapParams())
        }
    }

    @Test("JSValueDecodable.from returns instance")
    func fromJSValueReturnsInstance() throws {
        let context = JSContext()!
        let jsValue = JSValue(undefinedIn: context)!

        let result = try TONSwapManager.from(jsValue)

        #expect(result != nil)
    }
}
